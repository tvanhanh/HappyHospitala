import gymnasium as gym
import numpy as np
import pandas as pd

class PersonalFinanceEnv(gym.Env):
    def __init__(self, data_path):
        super().__init__()
        self.data = pd.read_csv(data_path)
        print(f"Data length: {len(self.data)}")
        self.current_step = 0
        self.account_balance = 0
        self.saving_balance = 0
       # self.debt_balance = self.data.iloc[0]['debt_balance']

        # Action: [essential_ratio, entertainment_ratio, saving_ratio, debt_payment_ratio, invest_ratio]
        self.action_space = gym.spaces.Box(0, 1, (5,))
        # Obs: income, essential_need, entertainment_need, unexpected_expense, saving_balance, debt_balance, investment_opportunity, inflation_rate, interest_rate
        self.observation_space = gym.spaces.Box(0, np.inf, (9,))

    def reset(self):
        self.current_step = 0
        self.account_balance = 0
        self.saving_balance = 0
        self.debt_balance = self.data.iloc[0]['debt_balance']
        return self._get_obs()

    def _get_obs(self):
        if self.current_step >= len(self.data):
            return np.zeros_like(self.observation_space.low)
        row = self.data.iloc[self.current_step]
        return np.array([
            row['income'],
            row['essential_need'],
            row['entertainment_need'],
            row['unexpected_expense'],
            self.saving_balance,
            self.debt_balance,
            row['investment_opportunity'],
            row['inflation_rate'],
            row['interest_rate']
        ])

    def step(self, action):
        if self.current_step >= len(self.data):
          return self._get_obs(), 0, True, {}
        row = self.data.iloc[self.current_step]
        income = row['income']
        essential_need = row['essential_need']
        entertainment_need = row['entertainment_need']
        unexpected_expense = row['unexpected_expense']
        investment_opportunity = row['investment_opportunity']
        inflation_rate = row['inflation_rate']
        interest_rate = row['interest_rate']

        self.account_balance += income

        # Normalize action ratios
        action = np.clip(action, 0, 1)
        total = np.sum(action)
        if total > 1:
            action = action / total
        
        # Unpack actions
        essential_ratio, entertainment_ratio, saving_ratio, debt_payment_ratio, invest_ratio = action

        # Chi tiêu
        essential_spent = essential_ratio * self.account_balance
        entertainment_spent = entertainment_ratio * self.account_balance
        saving_amount = saving_ratio * self.account_balance
        debt_payment = min(debt_payment_ratio * self.account_balance, self.debt_balance)
        invest_amount = invest_ratio * self.account_balance if investment_opportunity else 0

        overspend_penalty = max(0, essential_spent - essential_need) + max(0, entertainment_spent - entertainment_need)
        unexpected_penalty = unexpected_expense if saving_amount < unexpected_expense else 0

        # Reward
        reward = saving_amount * (1 + interest_rate)  # saving lãi suất
        reward -= saving_amount * inflation_rate  # saving bị lạm phát
        reward -= overspend_penalty
        reward -= unexpected_penalty
        reward += debt_payment * 0.1  # thưởng cho trả nợ
        reward += invest_amount * 0.05  # giả định lợi nhuận đầu tư

        self.saving_balance += saving_amount
        self.debt_balance -= debt_payment
        self.account_balance = 0  # reset sau khi phân bổ

        self.current_step += 1
        done = self.current_step >= len(self.data)

        return self._get_obs(), reward, done, {}
if __name__ == "__main__":
    try:
        env = PersonalFinanceEnv('data/synthetic_finance.csv')
        print("Khởi tạo môi trường thành công!")
        obs = env.reset()
        print("Observation:", obs)
        action = env.action_space.sample()
        obs, reward, done, info = env.step(action)
        print("Step result:", obs, reward, done, info)
    except Exception as e:
        print("Lỗi:", e)