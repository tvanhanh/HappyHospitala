import mongoose, { Document, Schema } from "mongoose";

/**
 * PremiumPackage — Gói dịch vụ cao cấp cho bệnh nhân
 * [BMC] Revenue Stream: Premium Sales + Subscription Fees (B2C)
 */
export interface IPremiumPackage extends Document {
  name: string;           // "Standard", "Silver", "Gold"
  slug: string;           // "standard", "silver", "gold"
  price: number;          // VND/tháng (0 = free)
  durationDays: number;   // 30, 90, 365
  features: string[];     // Danh sách tính năng
  color: string;          // Màu hiển thị UI
  icon: string;           // Icon name
  maxBookingsPerMonth?: number;   // Giới hạn đặt lịch/tháng (null = unlimited)
  priorityBooking: boolean;       // Ưu tiên slot đặt lịch
  aiDiagnosis: boolean;           // Truy cập AI diagnosis
  insuranceSupport: boolean;      // Hỗ trợ BHYT
  discountPercent: number;        // % giảm phí khám
  isActive: boolean;
  sortOrder: number;
}

const premiumPackageSchema = new Schema<IPremiumPackage>(
  {
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true, lowercase: true },
    price: { type: Number, required: true, min: 0 },
    durationDays: { type: Number, required: true, default: 30 },
    features: [{ type: String }],
    color: { type: String, default: "#1565C0" },
    icon: { type: String, default: "star" },
    maxBookingsPerMonth: { type: Number, default: null },
    priorityBooking: { type: Boolean, default: false },
    aiDiagnosis: { type: Boolean, default: false },
    insuranceSupport: { type: Boolean, default: false },
    discountPercent: { type: Number, default: 0, min: 0, max: 100 },
    isActive: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

/**
 * UserSubscription — Đăng ký gói premium của bệnh nhân
 */
export interface IUserSubscription extends Document {
  userId: mongoose.Types.ObjectId;
  packageId: mongoose.Types.ObjectId;
  startDate: Date;
  endDate: Date;
  status: "active" | "expired" | "cancelled";
  paymentMethod: "cash" | "vnpay" | "momo" | "banking";
  amountPaid: number;
  transactionId?: string;
  autoRenew: boolean;
}

const userSubscriptionSchema = new Schema<IUserSubscription>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    packageId: { type: Schema.Types.ObjectId, ref: "PremiumPackage", required: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    status: { type: String, enum: ["active", "expired", "cancelled"], default: "active" },
    paymentMethod: { type: String, enum: ["cash", "vnpay", "momo", "banking"], default: "cash" },
    amountPaid: { type: Number, default: 0 },
    transactionId: { type: String },
    autoRenew: { type: Boolean, default: false },
  },
  { timestamps: true }
);

userSubscriptionSchema.index({ userId: 1, status: 1 });
userSubscriptionSchema.index({ endDate: 1 });

export const PremiumPackage = mongoose.model<IPremiumPackage>("PremiumPackage", premiumPackageSchema);
export const UserSubscription = mongoose.model<IUserSubscription>("UserSubscription", userSubscriptionSchema);
