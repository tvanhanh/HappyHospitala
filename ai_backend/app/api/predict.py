from flask import Blueprint, request, jsonify
from app.models.predict_knn import predict_knn

predict_bp = Blueprint('predict_bp', __name__)

@predict_bp.route('/predict', methods=['POST'])
def predict_diabetes():
    try:
        data = request.get_json(silent=True)

        if data is None:
            return jsonify({
                "status": "error",
                "message": "Không nhận được dữ liệu JSON. Hãy kiểm tra lại Header Content-Type bên Frontend."
            }), 400

        result = predict_knn(data)

        if "error" in result:
            return jsonify({"status": "error", "message": result["error"]}), 400

        return jsonify({
            "status":           "success",
            "prediction":       result["prediction"],
            "prediction_label": result.get("prediction_label", ""),
            "probabilities":    result.get("probabilities", {}),
            "clinical_advice":  result.get("clinical_advice", ""),
            "rule_triggered":   result.get("rule_triggered", False),
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500