import { Schema, model, Document, Types } from 'mongoose';

// ĐỊNH NGHĨA CẤU TRÚC CHI TIẾT TỪNG MẶT HÀNG TRONG PHIẾU NHẬP
interface IImportDetail {
  medicineId: Types.ObjectId;      // Thuốc nào
  batchNumber: string;             // Số lô do bên giao hàng cấp
  manufacturingDate: Date;         // Ngày sản xuất
  expiryDate: Date;                // Hạn sử dụng
  quantity: number;                // Số lượng hộp/chai nhập vào
  importPrice: number;             // Giá nhập của mặt hàng này đợt này
  totalPrice: number;              // Thành tiền của mặt hàng (= quantity * importPrice)
}

// ĐỊNH NGHĨA CẤU TRÚC PHIẾU NHẬP TỔNG
export interface IImportReceipt extends Document {
  receiptCode: string;             // Mã phiếu nhập (Ví dụ: PN-20260610-001)
  supplierId: Types.ObjectId;      // FK tới Supplier (Nhập từ nhà cung cấp nào)
  importDate: Date;                // Ngày giờ nhập kho
  createdById: Types.ObjectId;     // FK tới User/Staff (Nhân viên nào lập phiếu)
  totalAmount: number;             // Tổng tiền của cả hóa đơn nhập
  notes?: string;                  // Ghi chú (Ví dụ: Hàng tặng kèm, thanh toán trước 50%...)
  status: 'pending' | 'completed' | 'cancelled'; // Trạng thái phiếu
  items: IImportDetail[];          // Mảng chứa danh sách chi tiết các thuốc nhập
  createdAt?: Date;
  updatedAt?: Date;
}

// SCHEMA CHI TIẾT LÔ THUỐC TRONG PHIẾU (Embedded Schema)
const ImportDetailSchema = new Schema<IImportDetail>({
  medicineId: {
    type: Schema.Types.ObjectId,
    ref: 'Medicine',
    required: [true, 'Phải chọn thuốc để nhập kho'],
  },
  batchNumber: {
    type: String,
    required: [true, 'Số lô của từng mặt hàng là bắt buộc'],
    trim: true,
  },
  manufacturingDate: {
    type: Date,
    required: [true, 'Ngày sản xuất là bắt buộc'],
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
  totalPrice: {
    type: Number,
    required: true,
  },
});

// SCHEMA CHÍNH CỦA PHIẾU NHẬP KHO
const ImportReceiptSchema = new Schema<IImportReceipt>(
  {
    receiptCode: {
      type: String,
      required: [true, 'Mã phiếu nhập kho là bắt buộc'],
      unique: true,
      trim: true,
    },
    supplierId: {
      type: Schema.Types.ObjectId,
      ref: 'Supplier', // Khớp nối với bảng Nhà cung cấp
      required: [true, 'Phải có thông tin nhà cung cấp'],
    },
    importDate: {
      type: Date,
      default: Date.now,
    },
    createdById: {
      type: Schema.Types.ObjectId,
      ref: 'User', // Hoặc 'Staff' tùy thuộc vào cách bạn đặt tên model tài khoản nhân viên
      required: [true, 'Phải có người lập phiếu nhập'],
    },
    totalAmount: {
      type: Number,
      required: true,
      default: 0,
    },
    notes: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'cancelled'],
      default: 'completed', // Mặc định tạo xong là đã hoàn thành nhập kho
    },
    items: [ImportDetailSchema], // 🟢 Nhúng mảng chi tiết vào trong phiếu nhập
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Tạo index để tìm kiếm phiếu nhập theo mã hoặc lọc theo ngày nhanh hơn
ImportReceiptSchema.index({ receiptCode: 1 });
ImportReceiptSchema.index({ importDate: -1 });

const ImportReceiptModel = model<IImportReceipt>('ImportReceipt', ImportReceiptSchema);

export default ImportReceiptModel;