# AI/callback/reward_logger_callback.py

import os
import pandas as pd
from stable_baselines3.common.callbacks import BaseCallback

class RewardLoggerCallback(BaseCallback):
    def __init__(self, save_path: str = 'logs/reward_log.csv', verbose=0):
        super().__init__(verbose)
        self.save_path = save_path
        self.episode_rewards = []
        self.episode_savings = []

    def _on_step(self) -> bool:
        if self.locals.get('dones'):
            for i, done in enumerate(self.locals['dones']):
                if done:
                    self.episode_rewards.append(self.locals['rewards'][i])
                    # lấy balance từ env nếu có
                    if hasattr(self.training_env.envs[i], 'saving_balance'):
                        self.episode_savings.append(self.training_env.envs[i].saving_balance)
                    else:
                        self.episode_savings.append(None)
        return True

    def _on_training_end(self) -> None:
        os.makedirs(os.path.dirname(self.save_path), exist_ok=True)
        df = pd.DataFrame({
            'reward': self.episode_rewards,
            'saving_balance': self.episode_savings
        })
        df.to_csv(self.save_path, index=False)
        if self.verbose > 0:
            print(f"✅ Logged {len(df)} episodes to {self.save_path}")
