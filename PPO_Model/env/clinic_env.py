import gymnasium as gym
from gymnasium import spaces
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler, LabelEncoder


class ClinicResourceEnv(gym.Env):
   

    def __init__(self, xlsx_path=None, data_df=None):
        super().__init__()

        # === LOAD DATA ===
        if data_df is not None:
            self.df = data_df.copy()
        elif xlsx_path is not None:
            self.df = pd.read_excel(xlsx_path, sheet_name="Detail data dataset")
        else:
            raise ValueError("Cần truyền xlsx_path hoặc data_df cho môi trường.")

        # === SANITIZE COLUMN NAMES ===
        self.df.columns = [c.strip().replace(" ", "_") for c in self.df.columns]

        # ==== CHECK REQUIRED COLUMNS ====
        required_cols = [
            "Staff_Id", "Bed_ID", "Dpt_ID", "ID", "Age",
            "Status", "treatemencost", "LOS", "ER_Time"
        ]

        for col in required_cols:
            if col not in self.df.columns:
                raise ValueError(f"Cột bắt buộc bị thiếu trong dataset: {col}")

        # ========= FEATURE ENGINEERING ===========
        self.df["PatientQueueLength"] = self.df["ER_Time"].fillna(0) / 10
        self.df["BedOccupancy"] = (self.df["Status"] != "Normal").astype(int)
        self.df["StaffAvailable"] = 1  # placeholder (tùy bạn xây thêm)
        self.df["EquipmentUtilization"] = np.random.uniform(0.2, 0.9, len(self.df))

        # Clean treatment cost
        self.df["treatemencost"] = (
            self.df["treatemencost"].astype(str)
            .replace(r"[$,]", "", regex=True)
            .astype(float)
        )

        # ===== Define numerical & categorical =====
        self.categorical_cols = ["Status", "Patient_Type"] if "Patient_Type" in self.df.columns else ["Status"]
        self.numerical_cols = [
            "StaffAvailable", "BedOccupancy",
            "PatientQueueLength",
            "EquipmentUtilization",
            "treatemencost",
            "LOS",
            "ER_Time",
            "Age",
        ]

        # Encode categorical
        for col in self.categorical_cols:
            self.df[col] = LabelEncoder().fit_transform(self.df[col].astype(str))

        # Combine feature list
        self.features = self.numerical_cols + self.categorical_cols

        # Scale
        self.scaler = StandardScaler()
        self.df[self.features] = self.scaler.fit_transform(self.df[self.features])
        self.df[self.features] = np.nan_to_num(self.df[self.features], nan=0.0)

        self.data = self.df[self.features].values
        self.current_index = 0
        self.total_steps = len(self.df)

        # === OBSERVATION SPACE ===
        self.observation_space = spaces.Box(
            low=-5, high=5, shape=(len(self.features),), dtype=np.float32
        )

        # === ACTION SPACE ===
        # 0 = allocate staff
        # 1 = allocate bed
        # 2 = allocate equipment
        self.action_space = spaces.Discrete(3)

    # ================= RESET =================
    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)
        self.current_index = 0
        obs = self.data[self.current_index].astype(np.float32)
        return obs, {}

    def step(self, action):
        row = self.df.iloc[self.current_index]

        # Lấy các giá trị (đã được chuẩn hóa bởi scaler nên thường nằm quanh mức 0)
        queue = row["PatientQueueLength"]
        occupancy = row["BedOccupancy"]
        er_time = row["ER_Time"]
        utilization = row["EquipmentUtilization"]

        # 1. HÀM PHẠT CƠ BẢN (Càng lớn càng bị trừ điểm)
        # Mục tiêu: Giảm thiểu các chỉ số này
        penalty = (
            0.5 * queue + 
            0.3 * er_time + 
            0.2 * row["LOS"]
        )
        
        reward = -penalty # Khởi đầu là điểm âm

        # 2. HÀM THƯỞNG CÓ ĐIỀU KIỆN (Chỉ cộng khi cần thiết)
        # Action 0: Thêm nhân sự - Chỉ thưởng nếu hàng đợi đang dài (> 0 là trên mức trung bình)
        if action == 0:
            if queue > 0:
                reward += 0.5 * queue # Thưởng tỷ lệ thuận với độ dài hàng đợi
            else:
                reward -= 0.2 # Phạt nhẹ vì lãng phí nhân sự khi không có hàng đợi

        # Action 1: Thêm giường - Chỉ thưởng khi tỷ lệ chiếm dụng cao
        elif action == 1:
            if occupancy > 0.5: # Giả sử trên 50% là cao
                reward += 0.4
            else:
                reward -= 0.1 # Phạt vì cấp giường dư thừa

        # Action 2: Cấp thiết bị - Thưởng khi hiệu suất sử dụng hiện tại thấp (cần đẩy mạnh)
        elif action == 2:
            if utilization < 0: # Dưới mức trung bình
                reward += 0.4 * (1 - utilization)
            else:
                reward += 0.1

        # 3. THƯỞNG DỰA TRÊN KẾT QUẢ CUỐI (Rating)
        if row["Rating"] == 5:
            reward += 0.5

        # ================= MOVE NEXT STEP =================
        self.current_index += 1
        done = self.current_index >= self.total_steps
        # ... (giữ nguyên phần trả về obs, done như cũ)

        # ================= MOVE NEXT STEP =================
        self.current_index += 1
        done = self.current_index >= self.total_steps

        if done:
            obs = np.zeros_like(self.data[0], dtype=np.float32)
        else:
            obs = self.data[self.current_index].astype(np.float32)

        return obs, reward, done, False, {}


# ================== TEST ENV ==================
if __name__ == "__main__":
    try:
        env = ClinicResourceEnv("data/Hospital_Health_Care_Management_Data_Set.xlsx")
        print("Environment loaded successfully!")

        obs, _ = env.reset()
        print("Initial Observation:", obs)

        action = env.action_space.sample()
        obs, reward, done, truncated, info = env.step(action)
        print("Step:", obs, reward, done)

    except Exception as e:
        print("Error:", e)
