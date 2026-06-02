import gymnasium as gym
from gymnasium import spaces
import pandas as pd
import numpy as np
import os
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import EvalCallback
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize

# --- BƯỚC 1: ĐỊNH NGHĨA MÔI TRƯỜNG VỚI 14 TRƯỜNG DỮ LIỆU ---
class SmartClinicEnvProV3(gym.Env):
    def __init__(self, csv_file):
        super(SmartClinicEnvProV3, self).__init__()
        self.df = pd.read_csv(csv_file).fillna(0)
        self.current_step = 0
        self.max_steps_per_episode = 1000 
        self.action_space = spaces.Discrete(12) # 5, 10, ..., 60 phút
        self.observation_space = spaces.Box(low=-1, high=10000, shape=(14,), dtype=np.float32)

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
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
        # Công thức quy đổi action sang phút: $Interval = (action + 1) \times 5$
        new_interval = (action + 1) * 5
        reward = 0
        
        # 1. Phạt hiệu suất mượt mà hơn
        reward -= (new_interval / 40) 

        # 2. LOGIC PHÂN TẦNG
        # Ca bình thường (Ưu tiên 5-15p)
        if row['Pool_Hours'] < 8 and row['Current_Stock'] >= row['Min_Required']:
            if new_interval <= 15: reward += 100 
            else: reward -= 50
        
        # Ca bác sĩ mệt (Ưu tiên 20-30p)
        elif row['Pool_Hours'] >= 9:
            if 20 <= new_interval <= 30: reward += 80
            elif new_interval < 20: reward -= 40

        # Ca nguy cấp (Ưu tiên 50p+)
        if row['Current_Stock'] < row['Min_Required'] or row['Patients_Assigned'] > 5:
            if new_interval >= 50: reward += 120 
            else: reward -= 70

        # 3. HÀNG RÀO AN TOÀN BỆNH NHÂN
        if row['waiting_time'] > 45: 
            reward -= 100 

        self.current_step += 1
        self.steps_taken += 1
        done = self.steps_taken >= self.max_steps_per_episode
        
        return self._get_observation() if not done else np.zeros(14), reward, done, False, {}

# --- BƯỚC 2: CẤU HÌNH HUẤN LUYỆN ---
if __name__ == "__main__":
    drive_path = "/content/drive/MyDrive/colab/PPO/"
    raw_env = SmartClinicEnvProV3(drive_path + "smart_clinic_standardized.csv")
    env = DummyVecEnv([lambda: raw_env])
    env = VecNormalize(env, norm_obs=True, norm_reward=True, clip_obs=10.)

    eval_callback = EvalCallback(
        env, 
        best_model_save_path=drive_path + 'logs/best_model_v3/',
        log_path=drive_path + 'logs_v3/', 
        eval_freq=20000, 
        n_eval_episodes=1, 
        deterministic=True, 
        render=False
    )

    model = PPO(
        policy="MlpPolicy",
        env=env,
        learning_rate=2e-4,     # Giảm nhẹ để học chắc chắn hơn
        n_steps=4096,           # AI nhìn bức tranh rộng hơn
        batch_size=128,         # Cập nhật chi tiết hơn
        n_epochs=10,            # Tăng số lần học lại
        gamma=0.95,             # Tập trung vào phần thưởng hiện tại
        verbose=1,
        device="cuda",
        tensorboard_log=drive_path + "tensorboard_v3/"
    )

    print("--- Khởi động huấn luyện 1 triệu bước với 14 trường dữ liệu ---")
    model.learn(total_timesteps=1000000, callback=eval_callback)

    model.save(drive_path + "ppo_smart_clinic_v3")
    env.save(drive_path + "vec_normalize_v3.pkl")
    print("DONE: Đã lưu mô hình và bộ chuẩn hóa thành công!")