import os
import joblib
import numpy as np

# ============================================================
# Ánh xạ nhãn mô hình → nhãn đầu ra API (Custom KNN)
#   Mô hình được train với class_mapping = {"N": 0, "Y": 1, "P": 2}
#     label 0 (N = Normal)         → output "Normal"      → code 0
#     label 1 (Y = Diabetic)       → output "Diabetes"    → code 2
#     label 2 (P = Pre-diabetic)   → output "Prediabetes" → code 1
# ============================================================
MODEL_LABEL_NAMES = {0: "Normal", 1: "Diabetes", 2: "Prediabetes"}
MODEL_TO_OUT_CODE = {0: 0,        1: 2,          2: 1}

FEATURES = ["Gender", "AGE", "Urea", "Cr", "HbA1c", "Chol", "TG", "HDL", "LDL", "VLDL", "BMI"]
HBA1C_IDX = 4  # index của HbA1c trong FEATURES


def predict_knn(data: dict) -> dict:
    """
    Trả về:
        {
            "prediction":      <int 0=Normal | 1=Prediabetes | 2=Diabetes>,
            "prediction_label": <str tên nhãn tiếng Việt>,
            "probabilities": {
                "Normal":      "XX.XX%",
                "Prediabetes": "XX.XX%",
                "Diabetes":    "XX.XX%"
            },
            "clinical_advice": <str lời khuyên lâm sàng>,
            "rule_triggered":  <bool True nếu chốt WHO/ADA kích hoạt>
        }
    Hoặc {"error": "<mô tả lỗi>"} nếu có lỗi.
    """
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
            # Giá trị mặc định khi thiếu
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

        # ── 🔒 Chốt chặn WHO/ADA: HbA1c ≥ 6.5% → Đái tháo đường ────────
        hba1c = x_values[HBA1C_IDX]
        if hba1c >= 6.5:
            return {
                "prediction":       2,
                "prediction_label": "Mắc bệnh tiểu đường",
                "probabilities": {
                    "Normal":      "0.0%",
                    "Prediabetes": "0.0%",
                    "Diabetes":    "100.0%",
                },
                "clinical_advice": (
                    "CẢNH BÁO: HbA1c ≥ 6.5% — Chẩn đoán Đái tháo đường theo tiêu chuẩn WHO/ADA. "
                    "Bệnh nhân cần hạn chế đường, tinh bột, kiểm tra đường huyết thường xuyên và "
                    "tham khảo bác sĩ chuyên khoa Nội tiết để bắt đầu phác đồ điều trị."
                ),
                "rule_triggered": True,
            }

        # ── Custom KNN Prediction (khi HbA1c < 6.5) ─────────────────────
        X        = np.array([x_values])
        X_scaled = scaler.transform(X)

        model_pred = int(model.predict(X_scaled)[0])

        # Lấy xác suất từ Custom KNN (thứ tự nội bộ: [Normal, Diabetic, Prediabetic])
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
        #   raw_probs[0] = P(N=Normal)      → key "Normal"
        #   raw_probs[1] = P(Y=Diabetic)    → key "Diabetes"
        #   raw_probs[2] = P(P=Prediabetic) → key "Prediabetes"
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
        elif out_code == 1:
            label_vi = "Tiền tiểu đường"
            advice   = (
                "CHÚ Ý: Các chỉ số cho thấy bệnh nhân đang ở giai đoạn Tiền tiểu đường. "
                "Cần giảm tinh bột, tăng hoạt động thể chất và theo dõi định kỳ để ngăn "
                "tiến triển thành Đái tháo đường."
            )
        else:  # out_code == 2
            label_vi = "Mắc bệnh tiểu đường"
            advice   = (
                "CẢNH BÁO: Chỉ số của bệnh nhân chỉ ra nguy cơ cao mắc bệnh tiểu đường. "
                "Cần hạn chế đường, tinh bột, kiểm tra đường huyết thường xuyên và tham "
                "khảo bác sĩ chuyên khoa Nội tiết để bắt đầu phác đồ điều trị."
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