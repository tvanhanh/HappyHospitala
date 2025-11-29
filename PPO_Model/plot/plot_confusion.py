import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
from stable_baselines3 import PPO  # hoặc A2C
from AI.env.person_loan_env import PersonalLoanEnv
import numpy as np

# Load environment và model
env = PersonalLoanEnv('data/dataset.csv')
model = PPO.load("models/ppo_loan_agent", env=env)  # thay bằng A2C.load nếu cần

# Lưu nhãn thật và dự đoán
y_true = []
y_pred = []

obs = env.reset()
done = False
while True:
    action, _ = model.predict(obs)
    y_pred.append(int(action))
    y_true.append(int(env.labels[env.current_index]))

    obs, reward, done, _ = env.step(action)
    if done:
        break

# Tạo confusion matrix
cm = confusion_matrix(y_true, y_pred)
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=["Negative", "Positive"])

# Vẽ
fig, ax = plt.subplots(figsize=(5, 5))
disp.plot(ax=ax, cmap=plt.cm.Blues, values_format='d')
plt.title("Confusion Matrix - PPO")
plt.show()
