from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
from PPO_Model.env.clinic_env import ClinicResourceEnv

app = FastAPI()

# Load model
model = PPO.load("models/ppo_clinic_resource")

env = ClinicResourceEnv()

# ===== Request schema =====
class StateInput(BaseModel):
    doctors: int
    nurses: int
    patients: int
    available_rooms: int
    emergency_cases: int

# ===== API =====
@app.post("/predictPPO")
def predict_action(state: StateInput):
    obs = [
        state.doctors,
        state.nurses,
        state.patients,
        state.available_rooms,
        state.emergency_cases
    ]

    action, _ = model.predict(obs, deterministic=True)

    return {
        "action": int(action)
    }
