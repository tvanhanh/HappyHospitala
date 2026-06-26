import sys
import os

# Dynamic path resolution to support running from both 'ai_backend' folder and root folder
current_dir = os.path.dirname(os.path.abspath(__file__))
ai_backend_dir = os.path.dirname(current_dir)
if ai_backend_dir not in sys.path:
    sys.path.insert(0, ai_backend_dir)

import numpy as np
from flask import Flask
from flask_cors import CORS

# ==========================================
# 0. ĐỊNH NGHĨA CLASS CustomKNN (BẮT BUỘC)
# Phải đặt ở đây để thư viện joblib/pickle có thể 
# nhận diện và map dữ liệu từ file .pkl vào object.
# ==========================================
class CustomKNN:
    def __init__(self, k=7):
        self.k = k
        
    def fit(self, X, y):
        self.X_train = np.array(X)
        self.y_train = np.array(y)
        
    def manhattan_distance(self, x1, x2):
        return np.sum(np.abs(x1 - x2))
        
    def predict(self, X):
        X = np.array(X)
        predictions = [self._predict_single(x) for x in X]
        return np.array(predictions)
        
    def _predict_single(self, x):
        distances = [self.manhattan_distance(x, x_train) for x_train in self.X_train]
        k_indices = np.argsort(distances)[:self.k]
        k_labels = [self.y_train[i] for i in k_indices]
        k_distances = [distances[i] for i in k_indices]
        weights = [1 / (d + 1e-10) for d in k_distances]
        weighted_votes = {}
        for label, weight in zip(k_labels, weights):
            weighted_votes[label] = weighted_votes.get(label, 0) + weight
        return max(weighted_votes, key=weighted_votes.get)
        
    def predict_proba(self, X):
        X = np.array(X)
        probas = []
        for x in X:
            distances = [self.manhattan_distance(x, x_train) for x_train in self.X_train]
            k_indices = np.argsort(distances)[:self.k]
            k_labels = [self.y_train[i] for i in k_indices]
            k_distances = [distances[i] for i in k_indices]
            weights = [1 / (d + 1e-10) for d in k_distances]
            total_weight = sum(weights)
            class_weights = {}
            for label, weight in zip(k_labels, weights):
                class_weights[label] = class_weights.get(label, 0) + weight
            proba = [class_weights.get(i, 0) / total_weight for i in range(3)]
            probas.append(proba)
        return np.array(probas)

# ==========================================
# 1. IMPORT CÁC BLUEPRINT (SAU KHI ĐÃ CÓ CLASS)
# ==========================================
from app.api.predict_skin import predict_skin_bp
from app.api.predict import predict_bp
from app.models.ai_manager import get_skin_model

# Khởi tạo Flask
app = Flask(__name__)
CORS(app)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Private-Network', 'true')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

# ==========================================
# 2. ĐĂNG KÝ BLUEPRINTS
# ==========================================
app.register_blueprint(predict_bp, url_prefix='/api')
app.register_blueprint(predict_skin_bp, url_prefix='/api')

# ==========================================
# 3. KHỞI CHẠY SERVER
# ==========================================
if __name__ == "__main__":
    print("\n" + "="*50)
    print("[STARTING] DANG KHOI DONG SERVER HAPPYCLINIC...")
    print("="*50)
    
    # BUC CHOT CHAN: NAP AI VAO BO NHO RAM
    try:
        print("[AI] Dang tai mo hinh hoc sau chuyen khoa Da Lieu (CNN)...")
        get_skin_model()
        print("[AI] Tai mo hinh Da Lieu thanh cong!")
    except Exception as e:
        print(f"[AI] Canh bao loi nap mo hinh Da Lieu: {e}")

    print("\n[SERVER] Server dang mo cong ket noi (0.0.0.0:5000)...")
    
    # LƯU Ý: Chuyển debug=False để tránh Flask khởi động 2 lần (làm Keras CNN bị crash RAM)
    app.run(debug=False, host='0.0.0.0', port=5000)