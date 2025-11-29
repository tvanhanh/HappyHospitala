import pandas as pd
import matplotlib.pyplot as plt

ppo_df = pd.read_csv("log/reward_log.csv")
baseline_df = pd.read_csv("log/baseline_random.csv")

plt.figure(figsize=(10,6))

plt.plot(ppo_df['episode'], ppo_df['reward'], label='PPO Reward', color='blue')
plt.plot(baseline_df['episode'], baseline_df['reward'], label='Random Agent', color='red', linestyle='--')

plt.xlabel("Episode")
plt.ylabel("Total Reward")
plt.title("Reward Comparison: PPO vs Random Agent")
plt.legend()
plt.grid(True)
plt.show()
