from flask import Flask, request, jsonify
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize
import gymnasium as gym

app = Flask(__name__)

# --- CẤU HÌNH MÔI TRƯỜNG GIẢ LẬP ---
class SmartClinicEnvPro(gym.Env):
    def __init__(self):
        super().__init__()
        # 14 trường dữ liệu đầu vào như đã train
        self.observation_space = gym.spaces.Box(low=-1, high=10000, shape=(14,), dtype=np.float32)
        self.action_space = gym.spaces.Discrete(12)

# --- NẠP MÔ HÌNH VÀ BỘ CHUẨN HÓA ---
# Đảm bảo 2 file này nằm cùng thư mục với app.py
ENV_PATH = "vec_normalize.pkl"
MODEL_PATH = "best_model.zip"

def load_ai_model():
    # Nạp bộ chuẩn hóa để AI hiểu đúng quy mô dữ liệu
    venv = DummyVecEnv([lambda: SmartClinicEnvPro()])
    venv = VecNormalize.load(ENV_PATH, venv)
    venv.training = False
    venv.norm_reward = False
    
    # Nạp bộ não PPO
    model = PPO.load(MODEL_PATH, env=venv)
    return model, venv

model, venv = load_ai_model()

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json.get('patient_data') # Mảng 14 số từ Frontend
        
        # 1. Chuẩn hóa dữ liệu đầu vào
        obs = venv.normalize_obs(np.array(data, dtype=np.float32))
        
        # 2. AI dự đoán
        action, _ = model.predict(obs, deterministic=True)
        
        # 3. Quy đổi ra phút: (Action + 1) * 5
        suggested_interval = int((action + 1) * 5)
        
        return jsonify({"suggested_interval": suggested_interval})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000, debug=True)