import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def plot_reward(df):
    df = pd.read_csv('logs/reward_log_ppo.csv')
    plt.figure(figsize=(10, 6))
    plt.plot(df.index, df['episode_reward'], label='Reward per step')
    plt.xlabel('Episode')
    plt.ylabel('Reward')
    plt.title('Reward per Episode')
    plt.legend()
    plt.grid()
    plt.show()
def plot_randum_ppo_reward(df):
    ppo_df = pd.read_csv("logs/reward_log_ppo.csv")
    baseline_df = pd.read_csv("logs/baseline_random.csv")
    rule = pd.read_csv("logs/rule_based.csv")

    plt.figure(figsize=(12,6))

    plt.plot(ppo_df['episode'], ppo_df['episode_reward'], label='PPO Reward', color='green')
    plt.plot(baseline_df['episode'], baseline_df['episode_reward'], label='Random Agent', color='red', linestyle='--')
    plt.plot(rule['episode'], rule['episode_reward'], label='Rule-based', color='blue')

    plt.xlabel("Episode")
    plt.ylabel("Total Reward")
    plt.title("Reward per Episode")
    plt.legend()
    plt.grid(True)
    plt.show()
def plot_credit_score_distribution(df):
    plt.figure(figsize=(8, 5))
    sns.histplot(df['CreditScore'], bins=30, kde=True, color='skyblue')
    plt.title('Credit Score Distribution')
    plt.xlabel('Credit Score')
    plt.ylabel('Count')
    plt.grid(True)
    plt.show()

def plot_loan_approval_by_purpose(df):
    plt.figure(figsize=(10, 6))
    sns.countplot(data=df, x='LoanPurpose', hue='LoanApproved')
    plt.xticks(rotation=45)
    plt.title('Loan Approval Rate by Loan Purpose')
    plt.xlabel('Loan Purpose')
    plt.ylabel('Count')
    plt.legend(title='Loan Approved')
    plt.tight_layout()
    plt.show()

def plot_debt_vs_income(df):
    plt.figure(figsize=(8, 5))
    sns.scatterplot(data=df, x='MonthlyIncome', y='TotalLiabilities', hue='LoanApproved')
    plt.title('Debt vs Income')
    plt.xlabel('Monthly Income')
    plt.ylabel('Total Liabilities')
    plt.grid(True)
    plt.tight_layout()
    plt.show()
def plot_interest_vs_risk(df):
    plt.figure(figsize=(8, 5))
    sns.scatterplot(data=df, x='RiskScore', y='InterestRate', hue='LoanApproved')
    plt.title('Interest Rate vs Risk Score')
    plt.xlabel('Risk Score')
    plt.ylabel('Interest Rate')
    plt.grid(True)
    plt.tight_layout()
    plt.show()
def plot_home_ownership_approval(df):
    plt.figure(figsize=(7, 5))
    sns.countplot(data=df, x='HomeOwnershipStatus', hue='LoanApproved')
    plt.title('Loan Approval by Home Ownership Status')
    plt.xlabel('Home Ownership Status')
    plt.ylabel('Count')
    plt.tight_layout()
    plt.show()

if __name__ == '__main__':
    csv_path = 'data/dataset.csv'
    df = pd.read_csv(csv_path)
    plot_reward(df)
    plot_randum_ppo_reward(df)
    plot_credit_score_distribution(df)
    plot_loan_approval_by_purpose(df)
    plot_debt_vs_income(df)
    plot_interest_vs_risk(df)
    plot_home_ownership_approval(df)

