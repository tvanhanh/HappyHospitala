import paho.mqtt.client as mqtt
import time
import json
import random

# Cấu hình
THINGSBOARD_HOST = 'thingsboard.cloud'
ACCESS_TOKEN = 'TOKEN_CUA_KHO_THUOC' # Thay bằng token của bạn

client = mqtt.Client()
client.username_pw_set(ACCESS_TOKEN)
client.connect(THINGSBOARD_HOST, 1883, 60)

print("Đang bắt đầu giả lập dữ liệu kho thuốc...")

try:
    while True:
        # Giả lập nhiệt độ chuẩn cho dược mỹ phẩm (18-25 độ C)
        payload = {
            "temperature": round(random.uniform(18.5, 26.0), 2),
            "humidity": random.randint(40, 60)
        }
        client.publish('v1/devices/me/telemetry', json.dumps(payload))
        print(f"Đã gửi dữ liệu kho: {payload}")
        time.sleep(10) # 10 giây gửi 1 lần
except KeyboardInterrupt:
    client.disconnect()