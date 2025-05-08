from flask import Blueprint
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import classification_report
from imblearn.over_sampling import SMOTE
from sklearn.preprocessing import StandardScaler
from joblib import dump
from app.config.dataset import patient_collection

train_knn_bp = Blueprint('train_knn', __name__)

@train_knn_bp.route('/train', methods=['POST'])
def train_knn_model():
    try:
        # 1. Đọc dữ liệu từ MongoDB
        data = list(patient_collection.find())
        if not data:
            return {"error": "Không tìm thấy dữ liệu trong MongoDB."}, 400

        df = pd.DataFrame(data)

        # 2. Tiền xử lý dữ liệu
        columns_to_drop = ["ID", "No_Pation", "_id"]
        df.drop(columns=[col for col in columns_to_drop if col in df.columns], inplace=True, errors="ignore")

        # Chuẩn hoá và kiểm tra cột Gender
        df["Gender"] = df["Gender"].astype(str).str.strip().str.lower()
        df["Gender"] = df["Gender"].replace({
            "male": "M", "m": "M", "nam": "M",
            "female": "F", "f": "F", "nữ": "F", "nu": "F"
        })
        if not df["Gender"].isin(["M", "F"]).all():
            return {"error": "Cột 'Gender' chứa giá trị không hợp lệ."}, 400
        df["Gender"] = df["Gender"].map({"M": 0, "F": 1})

        # Chuẩn hoá và kiểm tra cột CLASS
        df["CLASS"] = df["CLASS"].astype(str).str.strip().str.upper()
        df["CLASS"] = df["CLASS"].replace({
            "NO": "N", "NEGATIVE": "N", "N": "N",
            "YES": "Y", "Y": "Y", "POSITIVE": "Y",
            "P": "P"
        })
        if not df["CLASS"].isin(["P", "Y", "N"]).all():
            return {"error": "Cột 'CLASS' chứa giá trị không hợp lệ."}, 400
        df["CLASS"] = df["CLASS"].map({"N": 0, "Y": 1, "P": 2})

        # Xử lý missing values
        print("Missing values before imputation:\n", df.isnull().sum())
        df.fillna(df.median(numeric_only=True), inplace=True)

        # 3. Chọn đặc trưng
        selected_features = ["Gender", "AGE", "Urea", "Cr", "HbA1c", "Chol", "TG", "HDL", "LDL", "VLDL", "BMI"]
        missing_features = [col for col in selected_features if col not in df.columns]
        if missing_features:
            return {"error": f"Các cột không tồn tại trong dữ liệu: {missing_features}"}, 400

        X = df[selected_features]
        y = df["CLASS"]

        # 4. Cân bằng dữ liệu bằng SMOTE
        smote = SMOTE(random_state=42)
        X_res, y_res = smote.fit_resample(X, y)
        print("Class distribution before SMOTE:\n", y.value_counts())
        print("Class distribution after SMOTE:\n", y_res.value_counts())

        # 5. Train/Test split
        X_train, X_test, y_train, y_test = train_test_split(X_res, y_res, test_size=0.2, random_state=42, stratify=y_res)
        print(f"Training set: {X_train.shape}, Test set: {X_test.shape}")

        # 6. Chuẩn hóa dữ liệu
        scaler = StandardScaler()
        X_train = scaler.fit_transform(X_train)
        X_test = scaler.transform(X_test)
        dump(scaler, "app/models/scaler.pkl")

        # 7. Huấn luyện KNN
        model = KNeighborsClassifier(n_neighbors=5)
        model.fit(X_train, y_train)

        # 8. Đánh giá
        y_pred = model.predict(X_test)
        report = classification_report(y_test, y_pred, output_dict=True)
        print("Classification Report:\n", classification_report(y_test, y_pred))

        # 9. Lưu model
        dump(model, "app/models/knn_model.pkl")

        return {
            "message": "✅ Mô hình KNN đã được huấn luyện và lưu.",
            "accuracy": report["accuracy"],
            "report": report
        }, 200

    except Exception as e:
        return {"error": str(e)}, 500
