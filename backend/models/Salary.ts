import mongoose, { Document, Schema } from "mongoose";

/**
 * Salary — Bảng lương nhân viên / bác sĩ
 * Tính lương = baseSalary + (consultationCount × consultationRate)
 * [ERD Deviation] Entity mới, ghi chú báo cáo: "Mở rộng ERD để hỗ trợ HR module"
 */
export interface ISalary extends Document {
  userId: mongoose.Types.ObjectId;
  month: number;   // 1–12
  year: number;
  baseSalary: number;
  consultationCount: number;   // Số ca khám trong tháng
  consultationRate: number;    // Tiền/ca
  consultationBonus: number;   // = consultationCount × consultationRate
  allowances: number;          // Phụ cấp (xăng, ăn trưa...)
  deductions: number;          // Khấu trừ (bảo hiểm, thuế...)
  totalAmount: number;         // = baseSalary + consultationBonus + allowances - deductions
  status: "draft" | "pending" | "paid";
  paidAt?: Date;
  paidBy?: mongoose.Types.ObjectId;
  note?: string;
}

const salarySchema = new Schema<ISalary>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },
    baseSalary: { type: Number, default: 0 },
    consultationCount: { type: Number, default: 0 },
    consultationRate: { type: Number, default: 0 },
    consultationBonus: { type: Number, default: 0 },
    allowances: { type: Number, default: 0 },
    deductions: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    status: { type: String, enum: ["draft", "pending", "paid"], default: "draft" },
    paidAt: { type: Date },
    paidBy: { type: Schema.Types.ObjectId, ref: "User" },
    note: { type: String },
  },
  { timestamps: true }
);

// Unique constraint: 1 bảng lương/người/tháng
salarySchema.index({ userId: 1, month: 1, year: 1 }, { unique: true });

const Salary = mongoose.model<ISalary>("Salary", salarySchema);
export default Salary;
