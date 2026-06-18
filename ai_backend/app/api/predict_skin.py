from flask import Blueprint, request, jsonify
import numpy as np
from PIL import Image
import tensorflow as tf
import io
import os

# Khởi tạo Blueprint cho module dự đoán da liễu
skin_predict_bp = Blueprint('skin_predict', __name__)

# ---------------------------------------------------------
# 1. TÌM ĐƯỜNG DẪN VÀ LOAD MÔ HÌNH TFLITE
# ---------------------------------------------------------
# Lấy đường dẫn thư mục gốc của 'app'
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Trỏ tới thư mục models
MODEL_PATH = os.path.join(BASE_DIR, 'models', 'skin_cancer_b4_optimized.tflite')

try:
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print("✅ Đã load thành công mô hình AI Da Liễu B4!")
except Exception as e:
    print(f"❌ Lỗi load mô hình: {e}")

LABELS = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']

def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((380, 380)) # Chuẩn B4
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

# ---------------------------------------------------------
# 2. ĐỊNH NGHĨA API ROUTE
# ---------------------------------------------------------
@skin_predict_bp.route('/v1/predict-skin', methods=['POST'])
def predict_skin_lesion():
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "Không tìm thấy file ảnh."}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({"status": "error", "message": "Tên file rỗng."}), 400

    try:
        image_bytes = file.read()
        input_data = preprocess_image(image_bytes)
        
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        
        output_data = interpreter.get_tensor(output_details[0]['index'])
        probabilities = output_data[0]
        
        max_index = np.argmax(probabilities)
        predicted_class = LABELS[max_index]
        confidence = float(probabilities[max_index])
        
        # CHỐT CHẶN Y KHOA
        clinical_warning = False
        if predicted_class == 'nv' and confidence < 0.65:
            clinical_warning = True
            advice = "Dấu hiệu mập mờ, yêu cầu sinh thiết/khám chuyên khoa."
        elif predicted_class in ['mel', 'bcc', 'akiec']:
            advice = "CẢNH BÁO ÁC TÍNH: Cần can thiệp y tế gấp."
        else:
            advice = "Lành tính, tiếp tục theo dõi."

        return jsonify({
            "status": "success",
            "diagnosis": predicted_class,
            "confidence": round(confidence * 100, 2),
            "warning_flag": clinical_warning,
            "clinical_advice": advice,
            "raw_probabilities": {LABELS[i]: round(float(probabilities[i])*100, 2) for i in range(7)}
        }), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500