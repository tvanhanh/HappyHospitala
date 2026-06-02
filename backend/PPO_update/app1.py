from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize
import gymnasium as gym

app = Flask(__name__)

# --- BƯỚC 1: ĐỊNH NGHĨA MÔI TRƯỜNG ---
class SmartClinicEnvPro(gym.Env):
    def __init__(self):
        super().__init__()
        # 14 trường quan sát như đã huấn luyện
        self.observation_space = gym.spaces.Box(low=-1, high=10000, shape=(14,), dtype=np.float32)
        self.action_space = gym.spaces.Discrete(12)

# --- BƯỚC 2: NẠP MÔ HÌNH VÀ BỘ CHUẨN HÓA ---
import os

def load_resources():
    # Lấy đường dẫn của thư mục chứa file app1.py hiện tại
    base_path = os.path.dirname(os.path.abspath(__file__))
    vec_path = os.path.join(base_path, "vec_normalize_v3.pkl")
    model_path = os.path.join(base_path, "best_model3.zip")

    venv = DummyVecEnv([lambda: SmartClinicEnvPro()])
    # Sử dụng đường dẫn tuyệt đối để nạp
    venv = VecNormalize.load(vec_path, venv)
    venv.training = False
    venv.norm_reward = False
    
    model = PPO.load(model_path, env=venv)
    return model, venv
model, venv = load_resources()

# --- BƯỚC 3: HÀM DỰ ĐOÁN LOGIC NỘI BỘ ---
def internal_predict(data):
    obs = venv.normalize_obs(np.array(data, dtype=np.float32))
    action, _ = model.predict(obs, deterministic=True)
    return int((action + 1) * 5)

# --- BƯỚC 4: API CHO FRONTEND/BLOCKCHAIN ---
@app.route('/predict', methods=['POST'])
def predict_api():
    data = request.json.get('patient_data')
    result = internal_predict(data)
    return jsonify({"suggested_interval": result})

# --- BƯỚC 5: CHƯƠNG TRÌNH TỰ KIỂM TRA (SELF-TEST) ---
def run_self_test():
    print("\n" + "="*30)
    print("SMART CLINIC AI: STARTING SELF-TEST")
    print("="*30)
    
    test_cases = {
        "1. BINH THUONG (Bac si khoe, Kho du)": [25, 0, 480, 20, 1, 10, 2, 1,3.0, 50, 10, 5, 10, 3],
        "2. QUA TAI (Bac si lam 11.5h - Met)": [45, 1, 600, 30, 1, 15, 5, 3, 11.5, 40, 10, 5, 35, 9],
        "3. NGUY CAP (Kho het do + Dong nguoi)": [30, 0, 540, 15, 1, 5, 1, 2, 4.0, 1, 10, 5, 20, 10]
    }

    for name, data in test_cases.items():
        res = internal_predict(data)
        # Thay ký tự kim cương bằng văn bản đơn giản
        print(f"--- {name}:")
        print(f"   => AI goi y gian cach: {res} phut")
    
    print("="*30)
    print("TEST HOAN TAT. KHOI DONG FLASK SERVER...\n")

if __name__ == '__main__':
    # Chạy test trước khi bật server để đảm bảo logic đúng
    run_self_test()
    app.run(port=5000)