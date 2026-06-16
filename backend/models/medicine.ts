import { Schema, model, Document, Types } from 'mongoose';

export interface IMedicine extends Document {
  medicineCode: string;

  medicineName: string;
  categoryId: Types.ObjectId; 
  supplierId: Types.ObjectId; 
  dosage: string;
  unit: string;
  manufacturer: string;
  imageUrl?: string;
  sellingPrice: number;
  minStock:number
  description?: string;
  status: 'active' | 'inactive';
  createdAt?: Date;
  updatedAt?: Date;
}

const MedicineSchema = new Schema<IMedicine>(
  {
    medicineCode: {
      type: String,
      required: [true, 'Mã thuốc là bắt buộc'],
      unique: true, 
      trim: true,
    },
    medicineName: {
      type: String,
      required: [true, 'Tên thuốc là bắt buộc'],
      trim: true,
    },
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'MedicineCategories', 
      required: [true, 'Danh mục thuốc (categoryId) là bắt buộc'],
    },
    supplierId: {
      type: Schema.Types.ObjectId,
      ref: 'Supplier', 
      required: [true, 'Nhà cung cấp (supplierId) là bắt buộc'],
    },
    dosage: {
      type: String,
      required: [true, 'Hàm lượng thuốc là bắt buộc'],
      trim: true,
    },
    unit: {
      type: String,
      required: [true, 'Đơn vị tính là bắt buộc'],
      trim: true,
      default: 'Viên',
    },
    manufacturer: {
      type: String,
      required: [true, 'Nhà sản xuất là bắt buộc'],
      trim: true,
    },
    imageUrl: {
      type: String,
      trim: true,
      default: '', // 🟢 Mặc định để chuỗi rỗng nếu chưa upload ảnh
    },
    sellingPrice: {
      type: Number,
      required: [true, 'Giá bán của thuốc là bắt buộc'],
      min: [0, 'Giá bán không được nhỏ hơn 0'],
    },
    minStock: {
      type: Number,
      required: [true, 'Số lượng tồn kho tối thiểu là bắt buộc'],
      min: [0, 'Tồn kho tối thiểu không được nhỏ hơn 0'],
      default: 10,
    },
    description: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active', 
    },

  },
  {
    timestamps: true,
    versionKey: false, 
  }
);

// Tạo index hỗ trợ tìm kiếm nhanh theo tên thuốc
MedicineSchema.index({ medicineName: 'text' });

// 3. Xuất Model ra để sử dụng trong Controller
const MedicineModel = model<IMedicine>('Medicine', MedicineSchema);

export default MedicineModel;