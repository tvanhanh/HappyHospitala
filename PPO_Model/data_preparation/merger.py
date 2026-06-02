import pandas as pd
import numpy as np
import os
from datetime import datetime
from sklearn.preprocessing import LabelEncoder

# --- BUOC 1: THIET LAP DUONG DAN ---
base_path = os.path.dirname(os.path.abspath(__file__))

# --- BUOC 2: DOC DU LIEU ---
try:
    df_slots = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'slots.csv'))
    df_app = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'appointments.csv'))
    df_pat = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'patients.csv'))

    df_treat = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'patient_data.csv'))
    df_staff = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'staff_data.csv'))
    df_inventory = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'inventory_data.csv'))

    for df in [df_slots, df_app, df_pat, df_treat, df_staff, df_inventory]:
        df.columns = [str(c).strip() for c in df.columns]

    print("DONE: Doc du lieu thanh cong!") 
except Exception as e:
    print(f"ERROR: Loi doc file: {e}")
    exit()

# --- BUOC 3: XU LY NGUON 2 (XU LY HAU TO _x, _y) ---
src2 = pd.merge(df_slots, df_app, on='slot_id', how='left')

def time_to_min(t):
    try:
        if pd.isna(t): return 0
        h, m = map(int, str(t).split(':'))
        return h * 60 + m
    except: return 0

# CAP NHAT: Danh sach tim kiem bao gom ca hau to Pandas tu tao
time_cols = ['appointment_time_x', 'appointment_time', 'Appointment_Time', 'time']
actual_time_col = next((c for c in time_cols if c in src2.columns), None)

if actual_time_col:
    src2['appointment_time_min'] = src2[actual_time_col].apply(time_to_min)
    print(f"Da tim thay thoi gian tai cot: {actual_time_col}")
else:
    print(f"ERROR: Van khong tim thay cot thoi gian! Cot dang co: {src2.columns.tolist()}")
    exit()

# Xu ly tuoi
df_pat['dob'] = pd.to_datetime(df_pat['dob'])
# Tranh trung cot sex/age neu da co
cols_to_use = [c for c in ['patient_id', 'sex', 'age', 'dob'] if c in df_pat.columns]
src2 = pd.merge(src2, df_pat[cols_to_use], on='patient_id', how='left', suffixes=('', '_pat'))
src2['age'] = 2025 - pd.to_datetime(src2['dob']).dt.year

# --- BUOC 4: XU LY NGUON 1 ---
def get_staff_type(text):
    t = str(text).lower()
    if 'surgeons' in t: return 'Surgeons'
    if 'nurse' in t: return 'Nurse'
    if 'doctor' in t: return 'Doctor'
    return 'Other'

df_treat['Staff_Type_Needed'] = df_treat['Staff_Needed'].apply(get_staff_type)
df_staff['Staff_Type'] = df_staff['Staff_Type'].str.strip()

src1 = pd.merge(df_treat, df_staff, left_on='Staff_Type_Needed', right_on='Staff_Type', how='left')
src1 = pd.merge(src1, df_inventory, left_on='Supplies_Used', right_on='Item_Name', how='left')

# --- BUOC 5: BAC CAU GIA DINH (DA TOI UU BO NHO) ---
# 1. Chi lay cac cot can thiet tu src1 va loai bo trung lap de tiet kiem RAM
clinical_cols = ['Patient_ID', 'Primary_Diagnosis', 'Procedure_Performed', 
                 'Staff_Type', 'Current_Stock', 'Min_Required', 
                 'Avg_Usage_Per_Day', 'Patients_Assigned', 'Hours_Worked']
                 
# Loai bo cac dong trung ID trong ho so benh an de khong bi bung no du lieu
src1_unique = src1[clinical_cols].drop_duplicates(subset=['Patient_ID'])

# 2. Anh xa 111k lich hen sang ho so benh an
ids_clinical = src1_unique['Patient_ID'].unique()
np.random.seed(42)
mapping = {pid: np.random.choice(ids_clinical) for pid in src2['patient_id'].unique()}
src2['bridge_id'] = src2['patient_id'].map(mapping)

# 3. Ghep Master voi RAM tiet kiem
# Dung how='left' de giu dung 111,000 dong tu src2
master_df = pd.merge(src2, src1_unique, left_on='bridge_id', right_on='Patient_ID', how='left')

print(f"DONE: Da gop Master an toan. Tong so dong: {len(master_df)}")

# --- BUOC 6: LOC TRUONG & MA HOA ---
keep_cols = [
    'age', 'sex', 'appointment_time_min', 'appointment_duration', 'status',
    'scheduling_interval', 'Primary_Diagnosis', 'Procedure_Performed', 
    'Staff_Type', 'Current_Stock', 'Min_Required', 'Avg_Usage_Per_Day', 
    'Patients_Assigned', 'Hours_Worked', 'waiting_time'
]
final_df = master_df[[c for c in keep_cols if c in master_df.columns]].copy().fillna(0)

le = LabelEncoder()
for col in final_df.select_dtypes(include=['object']).columns:
    final_df[col] = le.fit_transform(final_df[col].astype(str))

# --- BUOC 7: LUU FILE ---
out_path = os.path.join(base_path, 'master_clinic_train_final2.csv')
final_df.to_csv(out_path, index=False)
print("--------------------------------------------------")
print(f"THANH CONG: Da luu file tai {out_path}")
print(f"Tong so dong: {len(final_df)}")
print("--------------------------------------------------")