from flask import Blueprint, request, jsonify
from app.models.predict_knn import predict_knn
import os

predict_bp = Blueprint('predict', __name__)

@predict_bp.route('/predict', methods=['POST'])
def predict_api():
    try:
        from app.config.dataset import patient_collection  # nếu bạn dùng MongoDB để log lại
        import os

        # Kiểm tra model & scaler
        model_path = "app/models/knn_model.pkl"
        scaler_path = "app/models/scaler.pkl"

        if not os.path.exists(model_path) or not os.path.exists(scaler_path):
            return jsonify({"error": "Model hoặc Scaler không tồn tại. Hãy huấn luyện trước."}), 400

        input_data = request.get_json()
        if not input_data:
            return jsonify({"error": "Không có dữ liệu gửi lên."}), 400

        # Danh sách trường yêu cầu
        required_fields = ["Gender", "AGE", "Urea", "Cr", "HbA1c", "Chol", "TG", "HDL", "LDL", "VLDL", "BMI"]
        missing_fields = [field for field in required_fields if field not in input_data]
        if missing_fields:
            return jsonify({"error": f"Thiếu các trường: {', '.join(missing_fields)}"}), 400

        # Mã hóa giới tính: "M" => 0, "F" => 1
        gender_map = {"M": 0, "F": 1}
        gender_raw = input_data["Gender"]
        if not isinstance(gender_raw, str) or gender_raw.strip().upper() not in gender_map:
            return jsonify({"error": "Giá trị Gender không hợp lệ. Chỉ nhận M hoặc F"}), 400

        input_data["Gender"] = gender_map[gender_raw.strip().upper()]

        # Chuyển các giá trị còn lại thành float
        for field in required_fields:
            if field != "Gender":
                try:
                    input_data[field] = float(input_data[field])
                except Exception:
                    return jsonify({"error": f"Trường {field} phải là số."}), 400

        # Dự đoán với mô hình
        from app.models.predict_knn import predict_knn
        prediction = predict_knn(input_data)

        return jsonify({"result": prediction}), 200

    except Exception as e:
        return jsonify({"error": f"Lỗi server: {str(e)}"}), 500
