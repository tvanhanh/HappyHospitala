import { Schema, model, Document } from 'mongoose';

export interface IBillServiceItem {
  name: string;
  sellingPrice: number;
}

export interface IBillMedicineItem {
  id: string;
  name: string;
  quantity: string;
  sellingPrice: number;
  unit: string;
}

// 2. Định nghĩa Interface tổng cho Bill Document
export interface IBill extends Document {
  patientId: string;
  patientName: string;
  timeArrived: string;
  paymentMethod: string;
  cashGiven: number;
  totalServicesPrice: number;
  totalMedicinesPrice: number;
  finalTotalPrice: number;
  medicines: IBillMedicineItem[];
  services: IBillServiceItem[];
  createdAt: Date;
}

// 3. Khởi tạo các Sub-Schema (Schema con)
const BillServiceItemSchema = new Schema<IBillServiceItem>({
  name: { type: String, default: 'Dịch vụ chỉ định' },
  sellingPrice: { type: Number, default: 0 }
}, { _id: false }); // Không tạo _id riêng cho từng item dịch vụ nếu không cần thiết

const BillMedicineItemSchema = new Schema<IBillMedicineItem>({
  id: { type: String, default: '' },
  name: { type: String, required: true },
  quantity: { type: String, default: '0' },
  sellingPrice: { type: Number, default: 0 },
  unit: { type: String, default: 'Đơn vị' } // Nhận từ Flutter (Hộp, vỉ, viên...)
}, { _id: false });

// 4. Khởi tạo Schema chính
const BillSchema = new Schema<IBill>({
  patientId: { type: String, required: true },
  patientName: { type: String, required: true },
  timeArrived: { type: String, default: 'Hôm nay' },
  paymentMethod: { type: String, default: 'Tiền mặt' },
  cashGiven: { type: Number, default: 0 },
  totalServicesPrice: { type: Number, default: 0 },
  totalMedicinesPrice: { type: Number, default: 0 },
  finalTotalPrice: { type: Number, required: true },
  medicines: [BillMedicineItemSchema],
  services: [BillServiceItemSchema],
  createdAt: { type: Date, default: Date.now }
}, { versionKey: false });

export const Bill = model<IBill>('Bill', BillSchema);