import { Schema, model, Document } from 'mongoose';

// Định nghĩa Interface đại diện cho kiểu dữ liệu Nhà cung cấp trong TypeScript
export interface ISupplier extends Document {
  supplierName: string;
  contactName?: string;
  phone: string;
  email?: string;
  supplierType: 'medicine_local' | 'medicine_import' | 'equipment' | 'consumables';
  status: 'active' | 'reviewing' | 'paused';
  address?: string;
  note?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Cấu hình Mongoose Schema
const supplierSchema = new Schema<ISupplier>(
  {
    supplierName: {
      type: String,
      required: [true, 'Tên nhà cung cấp không được để trống'],
      trim: true,
    },
    contactName: {
      type: String,
      trim: true,
      default: '',
    },
    phone: {
      type: String,
      required: [true, 'Số điện thoại không được để trống'],
      trim: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      default: '',
    },
    supplierType: {
      type: String,
      enum: ['medicine_local', 'medicine_import', 'equipment', 'consumables'],
      default: 'medicine_local',
    },
    status: {
      type: String,
      enum: ['active', 'reviewing', 'paused'],
      default: 'active',
    },
    address: {
      type: String,
      trim: true,
      default: '',
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
  },
  {
    timestamps: true, // Tự động quản lý thuộc tính createdAt và updatedAt
  }
);

export const Supplier = model<ISupplier>('Supplier', supplierSchema);