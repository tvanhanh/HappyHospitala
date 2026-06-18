from flask import Blueprint, request, jsonify

# IMPORT Đầu bếp từ file models/predict_knn.py
from app.models.predict_knn import predict_knn 

predict_bp = Blueprint('predict_bp', __name__)

@predict_bp.route('/predict', methods=['POST'])
def predict_diabetes():
    try:
        # 1. Bồi bàn nhận Order từ Frontend
        data = request.get_json()
        
        # 2. Bồi bàn mang vào bếp, nhờ Đầu bếp nấu (Gọi hàm từ file số 1)
        result = predict_knn(data)
        
        if "error" in result:
            return jsonify({"status": "error", "message": result["error"]}), 400
        
        # Bưng món ra cho Frontend (Phải khớp tên biến "prediction")
        return jsonify({
            "status": "success", 
            "prediction": result["prediction"],
            "probabilities": result.get("probabilities", {}),
            "clinical_advice": result.get("clinical_advice", "")  # ← Thêm lời khuyên lâm sàng
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500