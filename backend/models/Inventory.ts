import mongoose, { Schema, Document } from 'mongoose';

// 1. Định nghĩa Interface cho các thuộc tính của Inventory
export interface IInventory extends Document {
  medicineId: mongoose.Types.ObjectId;
  medicineName: string;
  batchNumber: string;
  importPrice: number;
  exportPrice: number;
  expiryDate: Date;
  originalQuantity: number;
  currentQuantity: number;
  importReceiptId: mongoose.Types.ObjectId;
  status: 'active' | 'out_of_stock' | 'expired';
  createdAt?: Date;
  updatedAt?: Date;
}

// 2. Tạo Schema dựa trên Interface
const InventorySchema: Schema = new Schema(
  {
    medicineId: {
      type: Schema.Types.ObjectId,
      ref: 'Medicine', // Thay bằng tên Model Thuốc thực tế của bạn nếu khác
      required: true
    },
    medicineName: {
      type: String,
      required: true
    },
    batchNumber: {
      type: String,
      required: true
    },
    importPrice: {
      type: Number,
      required: true,
      default: 0
    },
    exportPrice: { type: Number, required: true },
    expiryDate: {
      type: Date,
      required: true
    },
    originalQuantity: {
      type: Number,
      required: true
    },
    currentQuantity: {
      type: Number,
      required: true
    },
    importReceiptId: {
      type: Schema.Types.ObjectId,
      ref: 'ImportMedicine', // Thay bằng tên Model Phiếu Nhập thực tế của bạn nếu khác
      required: true
    },
    status: {
      type: String,
      enum: ['active', 'out_of_stock', 'expired'],
      default: 'active'
    }
  },
  {
    timestamps: true // Tự động quản lý createdAt và updatedAt
  }
);

// Tạo Index tăng tốc truy vấn tìm kiếm lô cận hạn
InventorySchema.index({ medicineId: 1, expiryDate: 1 });

// 3. Xuất Model ra ngoài để sử dụng
const Inventory = mongoose.model<IInventory>('Inventory', InventorySchema);
export default Inventory;