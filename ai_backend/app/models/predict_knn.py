import pandas as pd
from joblib import load

def predict_knn(input_data):
    try:
        # Load model và scaler
        model = load("app/models/knn_model.pkl")
        scaler = load("app/models/scaler.pkl")

        # Chuẩn bị dữ liệu đầu vào
        selected_features = ["Gender", "AGE", "Urea", "Cr", "HbA1c", "Chol", "TG", "HDL", "LDL", "VLDL", "BMI"]
        input_df = pd.DataFrame([input_data], columns=selected_features)

        # Chuẩn hóa dữ liệu
        input_scaled = scaler.transform(input_df)

        # Dự đoán
        prediction = model.predict(input_scaled)[0]
        prediction_proba = model.predict_proba(input_scaled)[0]

        # Ánh xạ kết quả
        class_mapping = {0: "Không mắc bệnh (N)", 1: "Mắc bệnh (Y)", 2: "Tiền tiểu đường (P)"}
        predicted_class = class_mapping[prediction]

        return {
            "prediction": predicted_class,
            "probabilities": {class_mapping[i]: prob for i, prob in enumerate(prediction_proba)}
        }

    except Exception as e:
        raise Exception(f"Lỗi khi dự đoán: {str(e)}")