import pandas as pd
import os

# --- BUOC 1: THIET LAP DUONG DAN ---
base_path = os.path.dirname(os.path.abspath(__file__))
# Su dung file 'master_clinic_raw.csv' ma ban da tao
file_path = os.path.join(base_path, 'master_clinic_raw.csv')

# --- BUOC 2: DOC DU LIEU ---
try:
    # Doc file voi encoding utf-8
    df = pd.read_csv(file_path, encoding='utf-8')
    df.columns = [str(c).strip() for c in df.columns]
    print(f"DONE: Da nap thanh cong {len(df)} dong du lieu.")
except Exception as e:
    print(f"ERROR: Khong the doc file. Hay kiem tra file 'master_clinic_raw.csv' co nam cung thu muc khong?")
    exit()

# --- BUOC 3: DEM CAC LOAI THU THUAT (PROCEDURE) ---
target_col = 'Procedure_Performed'

if target_col in df.columns:
    # 1. Dem so luong tuyet doi
    counts = df[target_col].value_counts()
    
    # 2. Tinh ty le phan tram (%)
    percentages = df[target_col].value_counts(normalize=True) * 100
    
    # 3. Gop lai thanh mot bang thong ke
    report = pd.DataFrame({
        'So_Luong': counts,
        'Ty_Le_Phan_Tram': percentages.round(2)
    })
    
    print("\n" + "="*55)
    print(" THONG KE CAC LOAI THU THUAT (PROCEDURE_PERFORMED) ")
    print("="*55)
    print(report)
    print("="*55)
    print(f"Tong cong co: {len(counts)} loai thu thuat khac nhau.")
    
    # Luu ket qua ra file CSV de ban lam bao cao
    out_stat = os.path.join(base_path, 'procedure_statistics.csv')
    report.to_csv(out_stat, encoding='utf-8')
    print(f"\nDONE: Da luu ket qua vao file: {out_stat}")
else:
    print(f"ERROR: Khong tim thay cot '{target_col}'. Cac cot dang co: {df.columns.tolist()}")