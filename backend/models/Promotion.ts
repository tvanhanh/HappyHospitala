import mongoose, { Document, Schema } from "mongoose";

/**
 * Promotion — Quản lý khuyến mãi & mã giảm giá
 * Bao gồm: seasonal discount, mã BHYT, new user discount
 * [BMC] Implement theo Revenue Streams: Transaction Fees + Partnership Revenue
 */
export interface IPromotion extends Document {
  code: string;
  name: string;
  description?: string;
  discountType: "percent" | "fixed";
  discountValue: number;
  minAmount?: number;        // Số tiền tối thiểu để áp dụng
  maxDiscount?: number;      // Giảm tối đa (cho percent type)
  maxUsage?: number;         // Tổng số lần sử dụng tối đa
  usedCount: number;
  applicableFor: "all" | "insurance" | "premium" | "new_patient";
  validFrom: Date;
  validTo: Date;
  isActive: boolean;
  createdBy?: mongoose.Types.ObjectId;
}

const promotionSchema = new Schema<IPromotion>(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    name: { type: String, required: true },
    description: { type: String },
    discountType: { type: String, enum: ["percent", "fixed"], required: true },
    discountValue: { type: Number, required: true, min: 0 },
    minAmount: { type: Number, default: 0 },
    maxDiscount: { type: Number },
    maxUsage: { type: Number },
    usedCount: { type: Number, default: 0 },
    applicableFor: {
      type: String,
      enum: ["all", "insurance", "premium", "new_patient"],
      default: "all",
    },
    validFrom: { type: Date, required: true },
    validTo: { type: Date, required: true },
    isActive: { type: Boolean, default: true },
    createdBy: { type: Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

// Index for active queries
promotionSchema.index({ validFrom: 1, validTo: 1, isActive: 1 });

const Promotion = mongoose.model<IPromotion>("Promotion", promotionSchema);
export default Promotion;
