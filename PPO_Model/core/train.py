from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env

from PPO_Model.env.clinic_env import ClinicResourceEnv
from PPO_Model.utils.networks import ClinicFeatureExtractor


def make_env():
    return ClinicResourceEnv(
        xlsx_path="data/Hospital_Health_Care_Management_Data_Set.xlsx"
    )


def main():
    env = make_env()
    check_env(env, warn=True)

    policy_kwargs = dict(
        features_extractor_class=ClinicFeatureExtractor,
        features_extractor_kwargs=dict(features_dim=128),
        net_arch=dict(pi=[128, 64], vf=[128, 64]),  # policy & value head
    )

    model = PPO(
        "MlpPolicy",
        env,
        policy_kwargs=policy_kwargs,
        verbose=1,
        n_steps=2048,
        batch_size=64,
        gamma=0.99,
        learning_rate=3e-4,
        tensorboard_log="./ppo_logs/",
    )

    model.learn(total_timesteps=100_000)
    model.save("models/ppo_clinic_resource")
    env.close()


if __name__ == "__main__":
    main()
