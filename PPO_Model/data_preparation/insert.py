import pandas as pd
import numpy as np
import os

# --- BUOC 1: DUONG DAN ---
base_path = os.path.dirname(os.path.abspath(__file__))
# Dam bao ten file khop voi file ban da tao truoc do
file_path = os.path.join(base_path, 'smart_clinic_train_set.csv')

# --- BUOC 2: DOC DU LIEU ---
try:
    # Su dung encoding='utf-8' de doc du lieu an toan
    df = pd.read_csv(file_path, encoding='utf-8')
    num_rows = len(df)
    print(f"DONE: Da nap file thanh cong voi {num_rows} dong.") 
except Exception as e:
    # In thong bao khong dau de tranh loi charmap
    print(f"ERROR: Khong tim thay file. Vui long kiem tra lai: {e}")
    exit()

# --- BUOC 3: THEM DU LIEU NGAU NHIEN ---
np.random.seed(42) 

# 1. Pool_Hours: Ngau nhien tu 1.0 den 12.0 gio
df['Pool_Hours'] = np.round(np.random.uniform(1.0, 12.0, size=num_rows), 2)

# 2. Patients_Assigned: Ngau nhien tu 3 den 5 ca
df['Patients_Assigned'] = np.random.randint(3, 6, size=num_rows) 

# --- BUOC 4: LUU FILE ---
# Luu de len file cu voi dinh dang utf-8
df.to_csv(file_path, index=False, encoding='utf-8')

print("--------------------------------------------------")
print(f"THANH CONG: Da them Pool_Hours va Patients_Assigned.")
print(f"Tong so dong da xu ly: {num_rows}")
print("Du lieu da san sang cho mo hinh AI PPO.")
print("--------------------------------------------------")