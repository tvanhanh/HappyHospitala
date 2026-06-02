import pandas as pd
import os

# --- BUOC 1: THIET LAP DUONG DAN ---
base_path = os.path.dirname(os.path.abspath(__file__))
input_path = os.path.join(base_path, 'smart_clinic_train_set.csv')
output_path = os.path.join(base_path, 'smart_clinic_standardized.csv') # File moi de so sanh

# --- BUOC 2: DOC DU LIEU ---
try:
    # Luon dung encoding='utf-8' de tranh loi charmap tren Windows
    df = pd.read_csv(input_path, encoding='utf-8')
    print(f"Da nap {len(df)} dong du lieu tu file goc.")
except Exception as e:
    print(f"Loi doc file: {e}"); exit()

# --- BUOC 3: CHUAN HOA DU LIEU THEO YEU CAU ---
# 1. Chuan hoa Status: did not attend=0, attended=1, cancelled=2
status_map = {'did not attend': 0, 'attended': 1, 'cancelled': 2}
df['status'] = df['status'].str.strip().str.lower().map(status_map).fillna(0).astype(int)

# 2. Chuan hoa Primary_Diagnosis: Diabetes=1, Fracture=2, Pneumonia=3, Appendicitis=4
diagnosis_map = {'Diabetes': 1, 'Fracture': 2, 'Pneumonia': 3, 'Appendicitis': 4}
df['Primary_Diagnosis'] = df['Primary_Diagnosis'].str.strip().map(diagnosis_map).fillna(0).astype(int)

# 3. Chuan hoa Procedure_Performed: Blood Test=1, MRI=2, Chest X-ray=3, Appendectomy=4
procedure_map = {'Blood Test': 1, 'MRI': 2, 'Chest X-ray': 3, 'Appendectomy': 4}
df['Procedure_Performed'] = df['Procedure_Performed'].str.strip().map(procedure_map).fillna(0).astype(int)

# --- BUOC 4: LUU THANH FILE MOI ---
try:
    df.to_csv(output_path, index=False, encoding='utf-8')
    print("--------------------------------------------------")
    print("THANH CONG: Da luu du lieu da chuan hoa ra file moi.")
    print(f"File goc: smart_clinic_train_set.csv")
    print(f"File moi: smart_clinic_standardized.csv")
    print("Hay mo ca hai file de so sanh cac cot: status, Diagnosis, Procedure.")
    print("--------------------------------------------------")
except PermissionError:
    print("LOI: Hay dong cac file Excel lien quan truoc khi chay!")