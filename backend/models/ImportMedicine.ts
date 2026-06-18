import { Schema, model, Document, Types } from 'mongoose';

// ĐỊNH NGHĨA CẤU TRÚC CHI TIẾT TỪNG MẶT HÀNG TRONG PHIẾU NHẬP
interface IImportItem {
  medicineId: Types.ObjectId;      // Thuốc nào (Liên kết sang bảng Medicine)
  medicineName: string;            // Tên thuốc hiển thị nhanh
  batchNumber: string;             // Số lô do bên giao hàng cấp
  manufacturingDate?: Date;        // Ngày sản xuất (Tùy chọn)
  expiryDate: Date;                // Hạn sử dụng
  quantity: number;                // Số lượng nhập vào
  importPrice: number;             // Giá nhập của đợt này
  sellingPrice: number;            // Giá bán đề xuất dành riêng cho lô này từ Flutter
  totalPrice: number;              // Thành tiền của mặt hàng (= quantity * importPrice)
}

// ĐỊNH NGHĨA CẤU TRÚC PHIẾU NHẬP TỔNG
export interface IImportBill extends Document {
  supplierId: Types.ObjectId;      // FK tới Supplier (Nhà cung cấp)
  importDate: Date;                // Ngày giờ nhập kho
  createdById?: Types.ObjectId;    // FK tới User/Staff (Nếu có liên kết tài khoản)
  createdBy?: string;              // Chuỗi string tên nhân viên nhận từ SharedPreferences của Flutter
  totalAmount: number;             // Tổng tiền của cả hóa đơn nhập
  note?: string;                   // Ghi chú phiếu nhập chung
  status: 'Chờ duyệt' | 'Đã duyệt' | 'Đã hủy'; // 🔥 Chuẩn Enum tiếng Việt để triệt tiêu lỗi ts(2367)
  products: IImportItem[];         // 🟢 Khớp chuẩn tên mảng 'products' từ Flutter
  createdAt?: Date;
  updatedAt?: Date;
}

// SCHEMA CHI TIẾT LÔ THUỐC TRONG PHIẾU (Embedded Schema)
const ImportItemSchema = new Schema<IImportItem>({
  medicineId: {
    type: Schema.Types.ObjectId,
    ref: 'Medicine',
    required: [true, 'Phải chọn thuốc để nhập kho'],
  },
  medicineName: {
    type: String,
    required: [true, 'Tên thuốc là bắt buộc'],
    trim: true,
  },
  batchNumber: {
    type: String,
    required: [true, 'Số lô của từng mặt hàng là bắt buộc'],
    trim: true,
  },
  manufacturingDate: {
    type: Date,
    required: false, 
  },
  expiryDate: {
    type: Date,
    required: [true, 'Hạn sử dụng là bắt buộc'],
  },
  quantity: {
    type: Number,
    required: [true, 'Số lượng nhập là bắt buộc'],
    min: [1, 'Số lượng nhập tối thiểu là 1'],
  },
  importPrice: {
    type: Number,
    required: [true, 'Giá nhập là bắt buộc'],
    min: [0, 'Giá nhập không được nhỏ hơn 0'],
  },
  sellingPrice: {
    type: Number,
    required: [true, 'Giá bán đề xuất cho lô hàng là bắt buộc'],
    min: [0, 'Giá bán không được nhỏ hơn 0'],
  },
  totalPrice: {
    type: Number,
    required: true,
  },
});

// SCHEMA CHÍNH CỦA PHIẾU NHẬP KHO
const ImportBillSchema = new Schema<IImportBill>(
  {
    supplierId: {
      type: Schema.Types.ObjectId,
      ref: 'Supplier', 
      required: [true, 'Phải có thông tin nhà cung cấp'],
    },
    importDate: {
      type: Date,
      default: Date.now,
    },
    createdById: {
      type: Schema.Types.ObjectId,
      ref: 'User', 
      required: false,
    },
    createdBy: {
      type: String, 
      default: 'Nhân viên kho',
    },
    totalAmount: {
      type: Number,
      required: true,
      default: 0,
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['Chờ duyệt', 'Đã duyệt', 'Đã hủy'],
      default: 'Chờ duyệt',
    },
    products: [ImportItemSchema], // 🟢 Sử dụng mảng products đồng bộ
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

ImportBillSchema.index({ importDate: -1 });

export const ImportModel = model<IImportBill>('ImportMedicine', ImportBillSchema);