import { Schema, model, Document, Types } from 'mongoose';

export interface IMedicineBatch extends Document {
  medicineId: Types.ObjectId;      // FK liên kết trực tiếp tới MedicineModel của bạn
  batchNumber: string;             // Số lô từ nhà sản xuất (Ví dụ: LOT2026A)
  manufacturingDate: Date;         // Ngày sản xuất
  expiryDate: Date;                // Hạn sử dụng (Dùng để bắt lỗi hết hạn)
  importPrice: number;             // Giá nhập của riêng lô này (Để tính lợi nhuận chính xác)
  sellingPrice: number;            // Giá bán của lô này (Có thể kế thừa từ Medicine hoặc ghi đè nếu đợt này tăng giá)
  quantity: number;                // Số lượng nhập kho ban đầu của lô
  remainingQuantity: number;       // Số lượng thực tế còn lại trong kho của lô này
  importDate: Date;                // Ngày nhập lô này vào kho
  status: 'active' | 'expired' | 'recalled' | 'sold_out';
  createdAt?: Date;
  updatedAt?: Date;
}

const MedicineBatchSchema = new Schema<IMedicineBatch>(
  {
    medicineId: {
      type: Schema.Types.ObjectId,
      ref: 'Medicine',             // 🟢 Khớp chuẩn xác với tên model 'Medicine' bạn đã định nghĩa
      required: [true, 'Lô thuốc phải liên kết với một mã thuốc gốc'],
    },
    batchNumber: {
      type: String,
      required: [true, 'Số lô thuốc là bắt buộc'],
      trim: true,
    },
    manufacturingDate: {
      type: Date,
      required: [true, 'Ngày sản xuất lô thuốc là bắt buộc'],
    },
    expiryDate: {
      type: Date,
      required: [true, 'Hạn sử dụng lô thuốc là bắt buộc'],
    },
    importPrice: {
      type: Number,
      required: [true, 'Giá nhập kho của lô thuốc là bắt buộc'],
      min: [0, 'Giá nhập không được nhỏ hơn 0'],
    },
    sellingPrice: {
      type: Number,
      required: [true, 'Giá bán của lô thuốc là bắt buộc'],
      min: [0, 'Giá bán không được nhỏ hơn 0'],
    },
    quantity: {
      type: Number,
      required: [true, 'Số lượng nhập của lô là bắt buộc'],
      min: [1, 'Số lượng nhập tối thiểu phải là 1'],
    },
    remainingQuantity: {
      type: Number,
      required: true,
      min: [0, 'Số lượng tồn kho của lô không được nhỏ hơn 0'],
    },
    importDate: {
      type: Date,
      default: Date.now,           // Tự động lấy ngày hiện tại làm ngày nhập kho
    },
    status: {
      type: String,
      enum: ['active', 'expired', 'recalled', 'sold_out'],
      default: 'active',
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

MedicineBatchSchema.index({ medicineId: 1, batchNumber: 1 }, { unique: true });
MedicineBatchSchema.index({ medicineId: 1, expiryDate: 1, remainingQuantity: 1 });
MedicineBatchSchema.pre<IMedicineBatch>('save', function (next) {
  // 1. Nếu số lượng tồn kho bằng 0 -> Chuyển trạng thái hết hàng
  if (this.remainingQuantity === 0) {
    this.status = 'sold_out';
  } 
  // 2. Nếu ngày hiện tại vượt quá hạn sử dụng -> Chuyển trạng thái hết hạn
  else if (this.expiryDate < new Date()) {
    this.status = 'expired';
  }
  next();
});

const MedicineBatchModel = model<IMedicineBatch>('MedicineBatch', MedicineBatchSchema);

export default MedicineBatchModel;