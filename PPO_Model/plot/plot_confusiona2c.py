import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix
from stable_baselines3 import A2C
from AI.env.person_loan_env import PersonalLoanEnv

# Tạo môi trường test
test_path = "data/test_tmp.csv"
env = PersonalLoanEnv(test_path)

# Load model SB3
model = A2C.load("models/a2c_loan_agent.zip", env=env)

y_true = []
y_pred = []

obs = env.reset()
done = False

while True:
    # Dự đoán action
    action, _ = model.predict(obs, deterministic=True)
    y_pred.append(int(action))

    # Lấy nhãn thực tế từ env.labels
    y_true.append(int(env.labels[env.current_index]))

    obs, reward, done, _ = env.step(action)
    if done:
        break

# Confusion matrix
cm = confusion_matrix(y_true, y_pred, labels=[0, 1])

# Vẽ
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
            xticklabels=["Negative", "Positive"],
            yticklabels=["Negative", "Positive"])
plt.xlabel("Predicted Label")
plt.ylabel("True Label")
plt.title("Confusion Matrix - A2C Loan Approval")
plt.show()

print("✅ Vẽ confusion matrix thành công!")
