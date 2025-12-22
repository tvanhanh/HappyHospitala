import os
import pandas as pd
from stable_baselines3.common.callbacks import BaseCallback

class RewardLoggerCallback(BaseCallback):
    def __init__(self, save_path: str = 'logs/reward_log.csv', verbose=0):
        super().__init__(verbose)
        self.save_path = save_path
        self.episode_rewards = []
        self.episode_savings = []
        self.episode_steps = []
        self.episode_ids = []
        self.episode_losses = [] 
        self.current_rewards = []
        self.current_savings = []
        self.episode_counter = 1

    def _on_step(self) -> bool:
        rewards = self.locals['rewards']
        infos = self.locals.get('infos', [{}] * len(rewards))

        for i in range(len(rewards)):
            self.current_rewards.append(rewards[i])
            if hasattr(self.training_env.envs[i], 'saving_balance'):
                self.current_savings.append(self.training_env.envs[i].saving_balance)

        # Nếu là kết thúc 1 episode
        if any([info.get('terminal_observation') is not None for info in infos]):
            self.episode_rewards.append(sum(self.current_rewards))
            self.episode_savings.append(self.current_savings[-1] if self.current_savings else None)
            self.episode_steps.append(len(self.current_rewards))
            self.episode_ids.append(self.episode_counter)

            #  Lấy loss từ logger
            value_loss = self.model.logger.name_to_value.get("train/value_loss", None)
            if value_loss is not None:
                self.episode_losses.append(value_loss)
            else:
                self.episode_losses.append("")

            self.episode_counter += 1
            self.current_rewards.clear()
            self.current_savings.clear()

        return True

    def _on_training_end(self) -> None:
        os.makedirs(os.path.dirname(self.save_path), exist_ok=True)
        df = pd.DataFrame({
            'episode': self.episode_ids,
            'episode_reward': self.episode_rewards,
            'final_saving_balance': self.episode_savings,
            'episode_steps': self.episode_steps,
            'loss': self.episode_losses
        })
        df.to_csv(self.save_path, index=False)
        if self.verbose > 0:
            print(f" Logged {len(df)} episodes to {self.save_path}")
