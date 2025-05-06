from flask import Blueprint, request, jsonify
from app.models.predict_knn import predict_knn
import os

predict_bp = Blueprint('predict', __name__)

@predict_bp.route('/predict', methods=['POST'])
def predict_api():
    try:
        import re
        from app.config.dataset import patient_collection

        # Kiểm tra model & scaler tồn tại
        model_path = "app/models/knn_model.pkl"
        scaler_path = "app/models/scaler.pkl"

        if not os.path.exists(model_path):
            return jsonify({"error": "Model file not found. Please train the model first by calling /api/train."}), 400
        if not os.path.exists(scaler_path):
            return jsonify({"error": "Scaler file not found. Please train the model first by calling /api/train."}), 400

        input_data = request.get_json()
        if not input_data:
            return jsonify({"error": "No input data provided."}), 400

        user_input = input_data.get('request', '').lower()

        if user_input == 'hello':
            return jsonify({"reply": "Xin chào, tôi là AI!"}), 201

        # Nếu dạng: dự đoán bệnh tiểu đường của bệnh nhân id là <id>
        match = re.search(r'id\s*la\s*(\w+)', user_input)
        if match:
            patient_id = int(match.group(1))
            patient = patient_collection.find_one({"ID": patient_id})

            if not patient:
                return jsonify({"reply": f"❌ Không tìm thấy bệnh nhân với ID: {patient_id}"}), 404

            input_for_prediction = {
                "Gender": patient.get("Gender", ""),
                "AGE": patient.get("AGE", 0),
                "Urea": patient.get("Urea", 0),
                "Cr": patient.get("Cr", 0),
                "HbA1c": patient.get("HbA1c", 0),
                "Chol": patient.get("Chol", 0),
                "TG": patient.get("TG", 0),
                "HDL": patient.get("HDL", 0),
                "LDL": patient.get("LDL", 0),
                "VLDL": patient.get("VLDL", 0),
                "BMI": patient.get("BMI", 0),
            }

            # Mã hóa giới tính
            gender_map = {"M": 0, "F": 1}
            input_for_prediction["Gender"] = gender_map.get(input_for_prediction["Gender"].strip().upper(), -1)

            if input_for_prediction["Gender"] == -1:
                return jsonify({"reply": "❌ Giá trị giới tính không hợp lệ"}), 400

            # Gọi mô hình dự đoán
            result = predict_knn(input_for_prediction)
            return jsonify({"reply": f"Kết quả dự đoán cho bệnh nhân {patient_id}: {result}"}), 200

        # Nếu không phải yêu cầu theo ID, xử lý như thường
        gender_map = {"M": 0, "F": 1}
        if "Gender" in input_data:
            input_data["Gender"] = gender_map.get(input_data["Gender"].strip().upper(), -1)
            if input_data["Gender"] == -1:
                return jsonify({"reply": "❌ Giá trị giới tính không hợp lệ"}), 400

        result = predict_knn(input_data)
        return jsonify({"reply": result}), 200

    except Exception as e:
        return jsonify({"error": f"Lỗi khi dự đoán: {str(e)}"}), 500
