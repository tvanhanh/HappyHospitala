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

    # ================= STEP =================
    def step(self, action):
        row = self.df.iloc[self.current_index]

        queue = row["PatientQueueLength"]
        occupancy = row["BedOccupancy"]
        los = row["LOS"]
        er = row["ER_Time"]
        cost = row["treatemencost"]

        # ================= REWARD FUNCTION =================
        # reward = minimise queue + los + er + cost
        # reward = maximise resource utilization
        reward = (
            -0.6 * queue
            - 0.4 * los
            - 0.3 * er
            - 0.2 * cost
            + 0.4 * row["EquipmentUtilization"]
        )

        # Action effect (giả định)
        if action == 0:  # allocate staff
            reward += 0.3
        elif action == 1:  # allocate bed
            reward += 0.2
        elif action == 2:  # allocate equipment
            reward += 0.25

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
