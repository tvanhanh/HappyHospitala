# app/models/ai_manager.py
import tensorflow as tf
from app.config.settings import MODEL_PATH

# Biến toàn cục bảo vệ RAM
SKIN_MODEL = None

def get_skin_model():
    """Hàm này giúp nạp model một lần duy nhất vào RAM (Singleton pattern)"""
    global SKIN_MODEL
    if SKIN_MODEL is None:
        try:
            # Patch for TF version mismatch (quantization_config error)
            from tensorflow.keras.layers import Dense
            original_dense_from_config = Dense.from_config
            @classmethod
            def custom_dense_from_config(cls, config):
                if 'quantization_config' in config:
                    del config['quantization_config']
                return original_dense_from_config(config)
            Dense.from_config = custom_dense_from_config

            print(f"Dang tai mo hinh Da phuong thuc tu: {MODEL_PATH}")
            SKIN_MODEL = tf.keras.models.load_model(MODEL_PATH, compile=False)
            print("Da tai thanh cong mo hinh!")
        except Exception as e:
            print(f"Loi tai mo hinh: {str(e)}")
            raise e
    return SKIN_MODEL