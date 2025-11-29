import matplotlib.pyplot as plt
import pandas as pd

# Hàm 1: Reward per step
def plot_loss(df):
    df = pd.read_csv('logs/reward_log_ppo.csv')
    plt.figure(figsize=(10, 5))
    plt.plot(df['episode'], df['loss'], label='Loss per Episode', color='red')
    plt.xlabel('Episode')
    plt.ylabel('Loss')
    plt.title('Loss per Episode')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()

# Hàm 2: Spending Trend theo thời gian
def plot_spending_trend(df):
    df['date'] = pd.to_datetime(df['date'])
    df = df[df['date'].dt.year == df['date'].dt.year.max()]  # Lọc năm gần nhất

    plt.figure(figsize=(12, 6))
    plt.plot(df['date'], df['essential_need'], label='Essential Need')
    plt.plot(df['date'], df['entertainment_need'], label='Entertainment Need')
    plt.plot(df['date'], df['unexpected_expense'], label='Unexpected Expense')
    plt.xlabel('Date')
    plt.ylabel('Amount')
    plt.title('Spending Trend Over Time (Recent Year)')
    plt.legend()
    plt.grid()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()

# Hàm 3: Economic impact
def plot_economic_impact(df):
    df['date'] = pd.to_datetime(df['date'])
    df['month'] = df['date'].dt.to_period('M').astype(str)
    df = df[df['date'].dt.year == df['date'].dt.year.max()]  # Lọc năm gần nhất

    plt.figure(figsize=(12, 6))
    plt.plot(df['month'], df['inflation_rate'] * 100, label='Inflation Rate', color='blue')
    plt.plot(df['month'], df['interest_rate'] * 100, label='Interest Rate', color='green')
    plt.xlabel('Month')
    plt.ylabel('Rate (%)')
    plt.title('Economic Impact: Inflation vs Interest Rate (Recent Year)')
    plt.grid(True)
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()

# Hàm 4: Spending Distribution theo tháng
def plot_spending_distribution(df):
    df['date'] = pd.to_datetime(df['date'])
    df['month'] = df['date'].dt.to_period('M').astype(str)
    df = df[df['date'].dt.year == df['date'].dt.year.max()]  # Lọc năm gần nhất

    monthly = df.groupby('month')[['essential_need', 'entertainment_need', 'unexpected_expense']].sum()

    plt.figure(figsize=(12, 6))
    plt.plot(monthly.index, monthly['essential_need'], label='Essential Need', color='blue')
    plt.plot(monthly.index, monthly['entertainment_need'], label='Entertainment Need', color='orange')
    plt.plot(monthly.index, monthly['unexpected_expense'], label='Unexpected Expense', color='green')
    plt.xlabel('Month')
    plt.ylabel('Total Spending')
    plt.title('Monthly Spending Distribution (Recent Year)')
    plt.legend()
    plt.grid()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()

# Hàm 5: Investment Opportunity
def plot_investment_opportunity(df):
    df['date'] = pd.to_datetime(df['date'])
    df['month'] = df['date'].dt.to_period('M').astype(str)
    df = df[df['date'].dt.year == df['date'].dt.year.max()]  # Lọc năm gần nhất

    monthly_opp = df.groupby('month')['investment_opportunity'].mean().reset_index()

    plt.figure(figsize=(12, 6))
    plt.bar(monthly_opp['month'], monthly_opp['investment_opportunity'], color='green', alpha=0.7)
    plt.xlabel('Month')
    plt.ylabel('Opportunity Value')
    plt.title('Investment Opportunities Over Time (Recent Year)')
    plt.grid(axis='y')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()

# Chạy tất cả
if __name__ == '__main__':
    csv_path = 'data/synthetic_finance.csv'
    df = pd.read_csv(csv_path)
    

    plot_loss(df)
    plot_spending_trend(df)
    plot_economic_impact(df)
    plot_spending_distribution(df)
    plot_investment_opportunity(df)
