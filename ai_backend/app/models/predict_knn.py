import os
import joblib
import numpy as np

# ============================================================
# Ánh xạ nhãn mô hình → nhãn đầu ra API (Custom KNN)
# ============================================================
MODEL_LABEL_NAMES = {0: "Normal", 1: "Diabetes", 2: "Prediabetes"}
MODEL_TO_OUT_CODE = {0: 0,        1: 1,          2: 2}

FEATURES = ["Gender", "AGE", "Urea", "Cr", "HbA1c", "Chol", "TG", "HDL", "LDL", "VLDL", "BMI"]

def predict_knn(data: dict) -> dict:
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))

        # ── Tải Model & Scaler ────────────────────────────────────────────
        model_path  = os.path.join(current_dir, "knn_custom_model.pkl")
        scaler_path = os.path.join(current_dir, "scaler.pkl")

        if not os.path.exists(model_path):
            return {"error": "Không tìm thấy mô hình KNN. Vui lòng kiểm tra lại tên file model."}
        if not os.path.exists(scaler_path):
            return {"error": "Không tìm thấy file Scaler. Vui lòng kiểm tra lại."}

        model  = joblib.load(model_path)
        scaler = joblib.load(scaler_path)

        # ── Tiền xử lý đầu vào ───────────────────────────────────────────
        x_values = []
        for f in FEATURES:
            val = data.get(f)
            # Giá trị mặc định khi thiếu (giữ nguyên logic gốc của bạn)
            if val is None or (isinstance(val, str) and val.strip() == ""):
                if   f == "Gender": val = 0.0
                elif f == "AGE":    val = 30.0
                elif f == "BMI":    val = 22.0
                else:               val = 0.0

            # Chuyển đổi chuỗi giới tính sang số
            if f == "Gender" and isinstance(val, str):
                v = val.strip().upper()
                val = 1.0 if v in ("F", "FEMALE") else 0.0

            x_values.append(float(val))

        # ── 🤖 AI XỬ LÝ 100% DỮ LIỆU TẠI ĐÂY (Đã xóa bỏ lệnh IF hardcode) ──
        X        = np.array([x_values])
        X_scaled = scaler.transform(X)

        model_pred = int(model.predict(X_scaled)[0])

        # Lấy xác suất từ Custom KNN
        raw_probs = [0.0, 0.0, 0.0]
        try:
            proba     = model.predict_proba(X_scaled)[0]
            raw_probs = [float(p) for p in proba]
        except Exception as pe:
            print("Prob error:", pe)
            raw_probs[model_pred] = 1.0

        # Chuẩn hóa tổng xác suất = 1
        total = sum(raw_probs)
        if total > 0:
            raw_probs = [p / total for p in raw_probs]

        # Ánh xạ sang không gian nhãn đầu ra
        probabilities = {
            "Normal":      f"{round(raw_probs[0] * 100, 2)}%",
            "Prediabetes": f"{round(raw_probs[2] * 100, 2)}%",
            "Diabetes":    f"{round(raw_probs[1] * 100, 2)}%",
        }

        # Mã dự đoán & nhãn tiếng Việt
        out_code = MODEL_TO_OUT_CODE[model_pred]

        if out_code == 0:
            label_vi = "Không mắc bệnh tiểu đường"
            advice   = (
                "Các chỉ số hóa sinh của bệnh nhân nằm trong giới hạn bình thường. "
                "Hãy duy trì chế độ ăn uống lành mạnh và tập thể dục thể thao đều đặn."
            )
        elif out_code == 2:
            label_vi = "Tiền tiểu đường"
            advice   = (
                "CHÚ Ý: Các chỉ số cho thấy bệnh nhân đang ở giai đoạn Tiền tiểu đường. "
                "Cần giảm tinh bột, tăng hoạt động thể chất và theo dõi định kỳ để ngăn "
                "tiến triển thành Đái tháo đường."
            )
        else:  # out_code == 2
            label_vi = "Mắc bệnh tiểu đường"
            advice   = (
                "CẢNH BÁO: Phân tích đa biến cho thấy nguy cơ cao mắc bệnh tiểu đường. "
                "Cần hạn chế đường, tinh bột, kiểm tra đường huyết thường xuyên và tham "
                "khảo bác sĩ chuyên khoa Nội tiết để chẩn đoán xác định và điều trị."
            )

        return {
            "prediction":       out_code,
            "prediction_label": label_vi,
            "probabilities":    probabilities,
            "clinical_advice":  advice,
            "rule_triggered":   False, 
        }

    except Exception as e:
        return {"error": str(e)}