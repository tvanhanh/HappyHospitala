import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from glob import glob
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler, label_binarize
from sklearn.metrics import confusion_matrix, accuracy_score, precision_recall_fscore_support, roc_curve, auc
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D, Input, Concatenate
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, ReduceLROnPlateau, EarlyStopping
from google.colab import drive

# =========================================================================
# 1. KẾT NỐI DRIVE & GIẢI NÉN
# =========================================================================
print("🔌 1. Đang kết nối Google Drive...")
drive.mount('/content/drive')

print("⚡ 2. Đang giải nén dữ liệu vào ổ cứng cục bộ...")
# !mkdir -p /content/dataset
# !unzip -q -o /content/drive/MyDrive/HAM10000/HAM10000_raw.zip -d /content/dataset/

# =========================================================================
# 2. XỬ LÝ METADATA LÂM SÀNG (ĐA PHƯƠNG THỨC)
# =========================================================================
print("📊 3. Đang tiền xử lý Dữ liệu Bệnh án (Tuổi, Giới tính, Vị trí)...")
metadata = pd.read_csv('/content/dataset/HAM10000_metadata.csv')
image_paths = {os.path.splitext(os.path.basename(x))[0]: x for x in glob('/content/dataset/**/*.jpg', recursive=True)}
metadata['path'] = metadata['image_id'].map(image_paths)
metadata = metadata.dropna(subset=['path'])

# Nội suy y khoa và Scaling
metadata['age'] = metadata['age'].fillna(metadata['age'].mean())
metadata['sex'] = metadata['sex'].fillna('unknown')
metadata['localization'] = metadata['localization'].fillna('unknown')

scaler = MinMaxScaler()
metadata['age_scaled'] = scaler.fit_transform(metadata[['age']])

# One-hot Encoding
metadata = pd.get_dummies(metadata, columns=['sex', 'localization'])
exclude_cols = ['lesion_id', 'image_id', 'dx', 'dx_type', 'age', 'path']
meta_cols = [col for col in metadata.columns if col not in exclude_cols]
num_meta_features = len(meta_cols)

# =========================================================================
# 3. CHIA TẬP VÀ CÂN BẰNG DỮ LIỆU (OVERSAMPLING)
# =========================================================================
print("\n🔥 4. Chia tập và Nhân bản dữ liệu an toàn...")
train_df, val_df = train_test_split(metadata, test_size=0.2, random_state=42, stratify=metadata['dx'])

max_size = train_df['dx'].value_counts().max() 
balanced_list = []
for class_name, group in train_df.groupby('dx'):
    balanced_list.append(group.sample(max_size, replace=True, random_state=42))
train_df_balanced = pd.concat(balanced_list, axis=0).sample(frac=1, random_state=42).reset_index(drop=True)

# =========================================================================
# 4. BỘ PHÁT DỮ LIỆU KÉP (CUSTOM DATA GENERATOR)
# =========================================================================
img_processor = ImageDataGenerator(
    rotation_range=25, width_shift_range=0.15, height_shift_range=0.15,
    zoom_range=0.15, horizontal_flip=True, vertical_flip=True,
    preprocessing_function=tf.keras.applications.efficientnet.preprocess_input
)
val_processor = ImageDataGenerator(preprocessing_function=tf.keras.applications.efficientnet.preprocess_input)

class MultiModalGenerator(tf.keras.utils.Sequence):
    def __init__(self, df, img_gen, batch_size, target_size, meta_cols, shuffle=True, is_training=True):
        self.df = df.reset_index(drop=True)
        self.img_gen = img_gen
        self.batch_size = batch_size
        self.target_size = target_size
        self.meta_cols = meta_cols
        self.shuffle = shuffle
        self.is_training = is_training
        self.labels = sorted(self.df['dx'].unique())
        self.label_map = {label: idx for idx, label in enumerate(self.labels)}
        self.indices = np.arange(len(self.df))
        if self.shuffle: np.random.shuffle(self.indices)

    def __len__(self):
        return int(np.ceil(len(self.df) / self.batch_size))

    def on_epoch_end(self):
        if self.shuffle: np.random.shuffle(self.indices)

    def __getitem__(self, index):
        batch_idx = self.indices[index * self.batch_size:(index + 1) * self.batch_size]
        batch_df = self.df.iloc[batch_idx]

        # 1. Ảnh
        X_img = np.zeros((len(batch_df), *self.target_size, 3), dtype=np.float32)
        for i, img_path in enumerate(batch_df['path']):
            img = tf.keras.preprocessing.image.load_img(img_path, target_size=self.target_size)
            img_array = tf.keras.preprocessing.image.img_to_array(img)
            if self.is_training: img_array = self.img_gen.random_transform(img_array)
            X_img[i] = self.img_gen.preprocessing_function(img_array)

        # 2. Metadata
        X_meta = batch_df[self.meta_cols].values.astype(np.float32)
        
        # 3. Nhãn (One-hot)
        y = np.zeros((len(batch_df), len(self.labels)), dtype=np.float32)
        for i, label in enumerate(batch_df['dx']):
            y[i, self.label_map[label]] = 1.0

        # TRẢ VỀ DẠNG TUPLE CHUẨN: ((Ảnh, Metadata), Nhãn)
        return (X_img, X_meta), y

train_generator = MultiModalGenerator(train_df_balanced, img_processor, batch_size=32, target_size=(380,380), meta_cols=meta_cols, shuffle=True, is_training=True)
val_generator = MultiModalGenerator(val_df, val_processor, batch_size=32, target_size=(380,380), meta_cols=meta_cols, shuffle=False, is_training=False)

# =========================================================================
# 5. KHỞI TẠO & HUẤN LUYỆN MẠNG CHỮ "Y"
# =========================================================================
print("\n🧠 5. Khởi tạo Kiến trúc Mạng Nơ-ron Đa phương thức...")
image_input = Input(shape=(380, 380, 3), name='image_input')
base_model = tf.keras.applications.EfficientNetB4(weights='imagenet', include_top=False)
base_model.trainable = False 
x_img = base_model(image_input)
x_img = GlobalAveragePooling2D()(x_img)
x_img = Dropout(0.5)(x_img) 

meta_input = Input(shape=(num_meta_features,), name='meta_input')
x_meta = Dense(64, activation='relu')(meta_input)
x_meta = Dropout(0.2)(x_meta)
x_meta = Dense(32, activation='relu')(x_meta)

combined = Concatenate()([x_img, x_meta])
z = Dense(128, activation='relu')(combined)
z = Dropout(0.4)(z)
output = Dense(7, activation='softmax', name='classifier_output')(z)

model = Model(inputs=[image_input, meta_input], outputs=output)

callbacks_list = [
    ModelCheckpoint('/content/drive/MyDrive/HAM10000/skin_cancer_multimodal_best.h5', monitor='val_loss', save_best_only=True, mode='min', verbose=1),
    ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=2, min_lr=1e-6, verbose=1),
    EarlyStopping(monitor='val_loss', patience=4, restore_best_weights=True, verbose=1)
]

# Định nghĩa Signature: Generator đã tự batch (batch_size=32), nên shape ở đây là (batch, ...)
# QUAN TRỌNG: MultiModalGenerator.__getitem__ trả về cả batch rồi,
# nên KHÔNG gọi thêm .batch() nữa để tránh double-batching gây lỗi shape.
BATCH_SIZE = 32
output_signature = (
    (
        tf.TensorSpec(shape=(None, 380, 380, 3), dtype=tf.float32),
        tf.TensorSpec(shape=(None, num_meta_features), dtype=tf.float32)
    ),
    tf.TensorSpec(shape=(None, 7), dtype=tf.float32)
)

train_ds = tf.data.Dataset.from_generator(
    lambda: train_generator,
    output_signature=output_signature
).prefetch(tf.data.AUTOTUNE)

val_ds = tf.data.Dataset.from_generator(
    lambda: val_generator,
    output_signature=output_signature
).prefetch(tf.data.AUTOTUNE)

# GIAI ĐOẠN 1: Warm-up — chỉ train đầu phân loại, base_model đóng băng
print("\n🚀 [GIAI ĐOẠN 1] Warm-up Đầu hội tụ...")
model.compile(optimizer=Adam(learning_rate=1e-3), loss='categorical_crossentropy', metrics=['accuracy'])
history_1 = model.fit(train_ds, epochs=3, validation_data=val_ds, callbacks=callbacks_list)

# GIAI ĐOẠN 2: Fine-tuning — mở khóa 100 lớp cuối của base_model
print("\n🔥 [GIAI ĐOẠN 2] Deep Fine-tuning toàn hệ thống...")
for layer in base_model.layers[-100:]:
    layer.trainable = True
# QUAN TRỌNG: Phải gọi compile lại sau khi mở khóa các lớp
model.compile(optimizer=Adam(learning_rate=1e-5), loss='categorical_crossentropy', metrics=['accuracy'])
history_2 = model.fit(train_ds, epochs=12, validation_data=val_ds, callbacks=callbacks_list)

# Gộp lịch sử huấn luyện của 2 giai đoạn để vẽ biểu đồ
combined_history = {key: history_1.history[key] + history_2.history[key] for key in history_1.history.keys()}
# =========================================================================
# 6. HỆ THỐNG ĐÁNH GIÁ & BÁO CÁO (ĐÃ ĐỒNG BỘ ĐA PHƯƠNG THỨC)
# =========================================================================
print("\n📊 ĐANG KHỞI TẠO BÁO CÁO LÂM SÀNG...")
plt.rcParams['figure.dpi'] = 300 
plt.rcParams['font.size'] = 11

# --- LẤY DỰ ĐOÁN TỪ GENERATOR KÉP ---
# --- LẤY DỰ ĐOÁN TỪ DATASET KÉP (CHUẨN HÓA ĐỊNH DẠNG) ---
# Vì lúc train ta dùng val_ds (đã batch), nên lúc predict phải dùng chính nó
y_pred_probs = model.predict(val_ds)
y_pred_classes = np.argmax(y_pred_probs, axis=1)

# Lấy nhãn thực tế (True Labels) từ tập Validation
labels_list = val_generator.labels
label_map = val_generator.label_map
# --- SỬA ĐOẠN LẤY Y_TRUE ĐỂ KHỚP VỚI VAL_DS ---
y_true = []
for batch_x, batch_y in val_ds:
    y_true.append(batch_y.numpy())
y_true = np.concatenate(y_true, axis=0)
y_true = np.argmax(y_true, axis=1)
overall_accuracy = accuracy_score(y_true, y_pred_classes)

# --- VẼ ĐỒ THỊ LEARNING CURVES ---
acc, val_acc = combined_history['accuracy'], combined_history['val_accuracy']
loss, val_loss = combined_history['loss'], combined_history['val_loss']
epochs_range = range(1, len(acc) + 1)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
ax1.plot(epochs_range, acc, label='Train Acc', lw=2); ax1.plot(epochs_range, val_acc, label='Val Acc', lw=2)
ax1.set_title('Đồ thị Accuracy (Multi-modal)'); ax1.legend(); ax1.grid(True, ls='--')
ax2.plot(epochs_range, loss, label='Train Loss', lw=2); ax2.plot(epochs_range, val_loss, label='Val Loss', lw=2)
ax2.set_title('Đồ thị Loss (Multi-modal)'); ax2.legend(); ax2.grid(True, ls='--')
plt.savefig('/content/drive/MyDrive/HAM10000/Learning_Curves_MultiModal.png')
plt.show()

# --- VẼ MA TRẬN NHẦM LẪN ---
cm = confusion_matrix(y_true, y_pred_classes)
plt.figure(figsize=(11, 9))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=labels_list, yticklabels=labels_list, annot_kws={"size": 12, "weight": "bold"})
plt.title('Ma trận Nhầm lẫn - Đa phương thức', fontweight='bold', pad=20)
plt.ylabel('Thực tế'); plt.xlabel('Dự đoán')
plt.savefig('/content/drive/MyDrive/HAM10000/Confusion_Matrix_MultiModal.png')
plt.show()

# --- IN BÁO CÁO LÂM SÀNG CHUẨN ---
print("\n" + "="*85)
print(f"🎯 ĐỘ CHÍNH XÁC TỔNG THỂ (OVERALL ACCURACY): {overall_accuracy:>10.2%}") 
print("-" * 85)
print(f"{'Loại Bệnh':<12} | {'Độ Nhạy (Recall)':<16} | {'Độ Đặc Hiệu':<16} | {'Precision':<12} | {'F1-Score':<10}")
print("-" * 85)
precision, recall, fscore, support = precision_recall_fscore_support(y_true, y_pred_classes, labels=range(7))
for i, label in enumerate(labels_list):
    TP, FP, FN = cm[i, i], cm[:, i].sum() - cm[i, i], cm[i, :].sum() - cm[i, i]
    TN = cm.sum() - (TP + FP + FN)
    specificity = TN / (TN + FP) if (TN + FP) > 0 else 0
    print(f"{label:<12} | {recall[i]:>15.2%} | {specificity:>15.2%} | {precision[i]:>11.2%} | {fscore[i]:>9.2f}")
print("=" * 85)

# --- VẼ ROC-AUC ---
y_true_bin = label_binarize(y_true, classes=range(7))
fpr = dict(); tpr = dict(); roc_auc = dict()
plt.figure(figsize=(11, 8.5))
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2']
for i, color in zip(range(7), colors):
    fpr[i], tpr[i], _ = roc_curve(y_true_bin[:, i], y_pred_probs[:, i])
    roc_auc[i] = auc(fpr[i], tpr[i])
    plt.plot(fpr[i], tpr[i], color=color, lw=2.5, label=f'ROC {labels_list[i].upper()} (AUC = {roc_auc[i]:.3f})')
plt.plot([0, 1], [0, 1], 'k--', lw=2, alpha=0.5) 
plt.legend(loc="lower right"); plt.grid(True, ls='--'); plt.title('Đường cong ROC - Đa phương thức')
plt.savefig('/content/drive/MyDrive/HAM10000/ROC_AUC_MultiModal.png')
plt.show()

# =========================================================================
# 7. CHUYỂN ĐỔI TFLITE (MULTI-INPUT)
# =========================================================================
print("\n📦 ĐANG ĐÓNG GÓI MÔ HÌNH TFLITE ĐA PHƯƠNG THỨC...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
tflite_save_path = '/content/drive/MyDrive/HAM10000/skin_cancer_multimodal_optimized.tflite'
with open(tflite_save_path, 'wb') as f:
    f.write(tflite_model)
print(f"🚀 XONG! Đã xuất file API siêu nhẹ tại: {tflite_save_path}")