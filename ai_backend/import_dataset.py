import pandas as pd
from pymongo import MongoClient 

# 🔗 Kết nối đến MongoDB Atlas
client = MongoClient("mongodb+srv://medicalrecord:123@cluster0.hqwl0gl.mongodb.net/medical_records?retryWrites=true&w=majority&appName=Cluster0")
db = client["datasets"] 
collection = db["dataset"] 

# Kiểm tra kết nối
print("Kết nối thành công! Database:", client.list_database_names())

csv_path = "E:/Python_AI/KNN_AI/KNN_dataset.csv"  
df = pd.read_csv(csv_path)


data = df.to_dict(orient="records")

# 📌 Import vào MongoDB
if data:
    collection.insert_many(data)
    print(" Import dữ liệu thành công! Số lượng:", len(data))
else:
    print(" Không có dữ liệu trong file CSV!")
