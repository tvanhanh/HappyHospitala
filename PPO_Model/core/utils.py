import numpy as np

def compute_gae(rewards, values, dones, gamma=0.99, lam=0.95):
    # rewards, values: lists (length T), dones: list of bools
    advantages = []
    gae = 0.0
    values_ext = values + [0.0]
    for step in reversed(range(len(rewards))):
        mask = 1.0 - float(dones[step])
        delta = rewards[step] + gamma * values_ext[step+1] * mask - values_ext[step]
        gae = delta + gamma * lam * mask * gae
        advantages.insert(0, gae)
    return advantages

def normalize(x):
    a = np.array(x, dtype=np.float32)
    return (a - a.mean()) / (a.std() + 1e-8)
