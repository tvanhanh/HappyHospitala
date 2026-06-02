import gymnasium as gym
from gymnasium import spaces
import pandas as pd
import numpy as np
import os
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import EvalCallback
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize

# --- BƯỚC 1: MÔI TRƯỜNG TỐI ƯU (GIỚI HẠN ĐỘ DÀI EPISODE) ---
class SmartClinicEnvPro(gym.Env):
    def __init__(self, csv_file):
        super(SmartClinicEnvPro, self).__init__()
        self.df = pd.read_csv(csv_file).fillna(0)
        self.current_step = 0
        self.max_steps_per_episode = 1000 # GIỚI HẠN để học nhanh hơn
        self.action_space = spaces.Discrete(12)
        self.observation_space = spaces.Box(low=-1, high=10000, shape=(14,), dtype=np.float32)

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        # Bắt đầu ngẫu nhiên trong dữ liệu để AI gặp nhiều kịch bản
        self.current_step = np.random.randint(0, len(self.df) - self.max_steps_per_episode)
        self.steps_taken = 0
        return self._get_observation(), {}

    def _get_observation(self):
        row = self.df.iloc[self.current_step]
        return np.array([
            row['age'], row['sex'], row['appointment_time_min'], row['appointment_duration'],
            row['status'], row['scheduling_interval'], row['Primary_Diagnosis'], 
            row['Procedure_Performed'], row['Pool_Hours'], row['Current_Stock'], 
            row['Min_Required'], row['Avg_Usage_Per_Day'], row['waiting_time'], 
            row['Patients_Assigned']
        ], dtype=np.float32)

    def step(self, action):
        row = self.df.iloc[self.current_step]
        new_interval = (action + 1) * 5
        reward = 0
        
        # --- REWARD LOGIC (GIỮ NGUYÊN ĐỘ XỊN) ---
        if row['waiting_time'] <= 15: reward += 25
        elif row['waiting_time'] > 45: reward -= 50
        if row['Pool_Hours'] > 10:
            if new_interval >= 30: reward += 20
            else: reward -= 40
        if row['Current_Stock'] < row['Min_Required']:
            if new_interval >= 45: reward += 30
            else: reward -= 35
        if row['Patients_Assigned'] > 4 and new_interval > row['scheduling_interval']:
            reward += 15

        self.current_step += 1
        self.steps_taken += 1
        # Kết thúc ca học sau 1000 bước thay vì đợi hết 111k dòng
        done = self.steps_taken >= self.max_steps_per_episode
        return self._get_observation() if not done else np.zeros(14), reward, done, False, {}

# --- BƯỚC 2: CẤU HÌNH TRAIN TỐC ĐỘ CAO ---
if __name__ == "__main__":
    # Đảm bảo đường dẫn Drive chuẩn
    drive_path = "/content/drive/MyDrive/colab/PPO/"
    raw_env = SmartClinicEnvPro(drive_path + "smart_clinic_standardized.csv")
    env = DummyVecEnv([lambda: raw_env])
    env = VecNormalize(env, norm_obs=True, norm_reward=True, clip_obs=10.)

    # GIẢM TẦN SUẤT ĐÁNH GIÁ: Đây là mấu chốt để FPS không bị tụt
    eval_callback = EvalCallback(
        env, 
        best_model_save_path=drive_path + 'logs/best_model/',
        log_path=drive_path + 'logs/', 
        eval_freq=20000,     # Tăng lên 20k bước mới check 1 lần
        n_eval_episodes=1,   # Chỉ chạy 1 bài kiểm tra (Thay vì 5 bài)
        deterministic=True, 
        render=False
    )

    model = PPO(
        policy="MlpPolicy",
        env=env,
        learning_rate=3e-4,
        n_steps=2048,
        batch_size=256,      # Tăng batch size để GPU chạy bốc hơn
        n_epochs=5,          # Giảm số lần học lại từ 10 xuống 5 để tiết kiệm thời gian
        verbose=1,
        device="cuda"        # ÉP BUỘC DÙNG GPU
    )

  
    model.learn(total_timesteps=1000000, callback=eval_callback) # Nâng lên 1M bước luôn cho máu

    model.save(drive_path + "ppo_smart_clinic_final_pro")
    env.save(drive_path + "vec_normalize.pkl")
