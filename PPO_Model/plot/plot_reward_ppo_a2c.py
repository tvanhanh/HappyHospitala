import pandas as pd
import matplotlib.pyplot as plt

# Đọc dữ liệu
ppo_data = pd.read_csv('logs/reward_log_ppo.csv')
a2c_data = pd.read_csv('logs/a2c.csv')

# Vẽ Episode Reward
plt.figure(figsize=(12, 5))
plt.subplot(1, 2, 1)
plt.plot(ppo_data['episode'], ppo_data['episode_reward'], label='PPO')
plt.plot(a2c_data['episode'], a2c_data['episode_reward'], label='A2C')
plt.xlabel("Episode")
plt.ylabel("Episode Reward")
plt.title("PPO vs A2C - Reward")
plt.legend()
plt.grid(True)

# Vẽ Loss nếu có
plt.subplot(1, 2, 2)
if 'loss' in ppo_data.columns and 'loss' in a2c_data.columns:
    plt.plot(ppo_data['episode'], ppo_data['loss'], label='PPO Loss')
    plt.plot(a2c_data['episode'], a2c_data['loss'], label='A2C Loss')
    plt.ylabel("Loss")
    plt.xlabel("Episode")
    plt.title("PPO vs A2C - Loss")
    plt.legend()
    plt.grid(True)
else:
    print("Không tìm thấy cột 'loss' trong dữ liệu.")

plt.tight_layout()
plt.show()
