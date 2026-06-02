import pandas as pd
import numpy as np
import os
from sklearn.preprocessing import LabelEncoder

# --- BƯỚC 1 & 2: THIẾT LẬP VÀ ĐỌC DỮ LIỆU GỐC ---
base_path = os.path.dirname(os.path.abspath(__file__))
try:
    df_slots = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'slots.csv'))
    df_app = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'appointments.csv'))
    df_pat = pd.read_csv(os.path.join(base_path, 'source_data_scheduling', 'patients.csv'))
    df_treat = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'patient_data.csv'))
    df_staff = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'staff_data.csv'))
    df_inventory = pd.read_csv(os.path.join(base_path, 'source_data_supply', 'inventory_data.csv'))

    for df in [df_slots, df_app, df_pat, df_treat, df_staff, df_inventory]:
        df.columns = [str(c).strip() for c in df.columns]
    print("DONE: Da nap du lieu thanh cong.")
except Exception as e:
    print(f"ERROR: {e}"); exit()

# --- BƯỚC 3: CHUẨN HÓA THỜI GIAN VÀ SẮP XẾP LỊCH TRÌNH ---
def time_to_min(t):
    try:
        dt = pd.to_datetime(str(t).strip())
        return dt.hour * 60 + dt.minute
    except: return 0

src2 = pd.merge(df_slots, df_app, on='slot_id', how='left')
src2['appointment_time_min'] = src2['appointment_time'].apply(time_to_min)
# Sắp xếp theo thời gian là điều kiện bắt buộc để mô phỏng tích lũy
src2 = src2.sort_values(by='appointment_time_min').reset_index(drop=True)

# --- BƯỚC 4: KHỞI TẠO TRẠNG THÁI ĐỘNG (DYNAMIC STATE) ---
# 1. Trạng thái kho vật tư ban đầu
inventory_state = df_inventory.set_index('Item_Name')['Current_Stock'].to_dict()

# 2. Trạng thái nhân sự ban đầu (Gồm cả Surgeon)
staff_roles = ['Doctor', 'Nurse', 'Surgeon']
staff_load = {role: 10 for role in staff_roles}
staff_hours = {role: 0.0 for role in staff_roles}

# --- BƯỚC 5: MÔ PHỎNG BIẾN THIÊN TỪNG CA KHÁM (DYNAMIC LOOP) ---
master_rows = []
np.random.seed(42)

# Chuẩn bị dữ liệu lâm sàng mẫu
clinical_pool = pd.merge(df_treat, df_inventory, left_on='Supplies_Used', right_on='Item_Name', how='left')
clinical_pool = clinical_pool[['Primary_Diagnosis', 'Procedure_Performed', 'Supplies_Used', 'Avg_Usage_Per_Day']].drop_duplicates()



for i, row in src2.iterrows():
    # 1. Lấy mẫu chẩn đoán và thủ thuật ngẫu nhiên
    clin = clinical_pool.sample(1).iloc[0]
    # Sửa lỗi AttributeError: Sử dụng .title() trực tiếp trên chuỗi
    item_key = str(clin['Supplies_Used']).strip().title()
    usage = clin['Avg_Usage_Per_Day'] if clin['Avg_Usage_Per_Day'] > 0 else 1
    
    # 2. Cập nhật Kho (Giảm dần sau mỗi ca)
    if item_key in inventory_state:
        inventory_state[item_key] = max(0, inventory_state[item_key] - usage)
        current_stock = inventory_state[item_key]
    else: current_stock = 0

    # 3. Cập nhật Nhân sự (Giờ làm tăng dần - Burnout)
    duration_h = row['appointment_duration'] / 60.0
    for role in staff_roles:
        # Cộng dồn giờ làm và biến thiên tải trọng ngẫu nhiên
        staff_hours[role] += (duration_h * np.random.uniform(0.6, 1.3))
        staff_load[role] = max(0, staff_load[role] + np.random.randint(-1, 3))

    # 4. Lưu lại Snapshot trạng thái tại thời điểm này
    master_rows.append({
        'age': 2025 - pd.to_datetime(row['dob'], errors='coerce').year if pd.notna(row['dob']) else 30,
        'sex': 1 if str(row['sex']).lower() == 'male' else 0,
        'appointment_time_min': row['appointment_time_min'],
        'appointment_duration': row['appointment_duration'],
        'status': row['status'],
        'Primary_Diagnosis': clin['Primary_Diagnosis'],
        'Procedure_Performed': clin['Procedure_Performed'],
        'Pool_Load_Doctor': staff_load['Doctor'],
        'Max_Hours_Doctor': round(staff_hours['Doctor'], 2),
        'Pool_Load_Nurse': staff_load['Nurse'],
        'Max_Hours_Nurse': round(staff_hours['Nurse'], 2),
        'Pool_Load_Surgeon': staff_load['Surgeon'],
        'Max_Hours_Surgeon': round(staff_hours['Surgeon'], 2),
        'Current_Stock': current_stock,
        'waiting_time': row['waiting_time']
    })

final_df = pd.DataFrame(master_rows).fillna(0)

# --- BƯỚC 6: MÃ HÓA LABEL (CHUYỂN CHỮ THÀNH SỐ CHO AI) ---
# le = LabelEncoder()
# categorical_cols = ['status', 'Primary_Diagnosis', 'Procedure_Performed']
# for col in categorical_cols:
#     final_df[col] = le.fit_transform(final_df[col].astype(str))

# --- BƯỚC 7: LƯU KẾT QUẢ ---
out_path = os.path.join(base_path, 'smart_clinic_train_set.csv')
final_df.to_csv(out_path, index=False)
# --- CAP NHAT CAC DONG PRINT TRONG CODE ---
# Thay vi: print("DONE: Đã nạp dữ liệu thành công.")
# Hay dung:
print("DONE: Da nap du lieu thanh cong.") 

# --- CAP NHAT BUOC 7: LUU FILE ---
# Luon su dung encoding='utf-8' de bao ve du lieu y te co dau
out_path = os.path.join(base_path, 'smart_clinic_train_set.csv')
final_df.to_csv(out_path, index=False, encoding='utf-8')

print("--------------------------------------------------")
print(f"THANH CONG: Da tao file du lieu tai: {out_path}")
print("Du lieu da san sang cho mo hinh AI PPO.")
print("--------------------------------------------------")