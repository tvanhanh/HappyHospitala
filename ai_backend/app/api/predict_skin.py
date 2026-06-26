# app/api/predict_skin.py
import sys
import os

# Dynamic path resolution to support running/analyzing this file directly
current_dir = os.path.dirname(os.path.abspath(__file__))
app_dir = os.path.dirname(current_dir)
ai_backend_dir = os.path.dirname(app_dir)
if ai_backend_dir not in sys.path:
    sys.path.insert(0, ai_backend_dir)

import numpy as np
from PIL import Image
from io import BytesIO
from flask import Blueprint, request, jsonify
import tensorflow as tf

from app.config.settings import LABELS, AGE_MIN, AGE_MAX, EXPECTED_META_COLS
from app.models.ai_manager import get_skin_model

# Tạo Blueprint
predict_skin_bp = Blueprint('predict_skin_bp', __name__)

def preprocess_metadata(age: float, sex: str, localization: str):
    age_scaled = max(0.0, min(1.0, (age - AGE_MIN) / (AGE_MAX - AGE_MIN)))

    meta_dict = {col: 0.0 for col in EXPECTED_META_COLS}
    meta_dict['age_scaled'] = age_scaled

    sex_key = f'sex_{sex.lower()}'
    if sex_key in meta_dict:
        meta_dict[sex_key] = 1.0
    else:
        meta_dict['sex_unknown'] = 1.0

    loc_key = f'localization_{localization.lower()}'
    if loc_key in meta_dict:
        meta_dict[loc_key] = 1.0
    else:
        meta_dict['localization_unknown'] = 1.0

    return np.array([list(meta_dict.values())], dtype=np.float32)

@predict_skin_bp.route('/predict_skin', methods=['POST'])
def handle_prediction():
    try:
        # Lấy mô hình từ Singleton Manager
        model = get_skin_model()
        if model is None:
            return jsonify({"status": "error", "message": "Model error"}), 500

        # Lấy dữ liệu Request
        file = request.files.get('file')
        age = request.form.get('age', default=50.0, type=float)
        sex = request.form.get('sex', default='unknown', type=str)
        localization = request.form.get('localization', default='unknown', type=str)

        if not file:
            return jsonify({"status": "error", "message": "Không tìm thấy file ảnh."}), 400

        # Tiền xử lý Ảnh
        img = Image.open(file.stream).convert("RGB")
        img = img.resize((380, 380))
        img_array = tf.keras.preprocessing.image.img_to_array(img)
        img_array = tf.keras.applications.efficientnet.preprocess_input(img_array)
        img_array = np.expand_dims(img_array, axis=0)

        # Tiền xử lý Bệnh án
        meta_array = preprocess_metadata(age, sex, localization)

        # Suy luận
        preds = model.predict([img_array, meta_array], verbose=0)[0]
        
        # Sắp xếp để lấy Top 3
        top_indices = np.argsort(preds)[::-1][:3]
        top_3_predictions = []
        for idx in top_indices:
            top_3_predictions.append({
                "diagnosis": LABELS[int(idx)],
                "confidence_percent": round(float(preds[idx]) * 100, 2)
            })
            
        top_diagnosis = top_3_predictions[0]["diagnosis"]
        confidence = top_3_predictions[0]["confidence_percent"]

        # Kiểm tra nguy cơ ung thư (>15%)
        cancer_classes = ['mel', 'bcc', 'akiec']
        has_cancer_risk = any(float(preds[LABELS.index(c)]) > 0.15 for c in cancer_classes)

        if has_cancer_risk:
            recommendation = "CẢNH BÁO: Phát hiện dấu hiệu ác tính tiềm ẩn (>15%). Khuyến nghị sinh thiết hoặc soi da chuyên sâu!"
        else:
            recommendation = "Tổn thương có dấu hiệu lành tính. Khuyến nghị theo dõi định kỳ."

        # Trả kết quả JSON
        return jsonify({
            "status": "success",
            "data": {
                "diagnosis": top_diagnosis,
                "confidence_percent": confidence,
                "top_3_predictions": top_3_predictions,
                "has_cancer_risk": has_cancer_risk,
                "patient_info": {
                    "age": age,
                    "sex": sex,
                    "localization": localization
                },
                "medical_recommendation": recommendation
            }
        }), 200

    except Exception as e:
        print("API Error:", str(e).encode('ascii', 'ignore'))
        return jsonify({"status": "error", "message": str(e)}), 500