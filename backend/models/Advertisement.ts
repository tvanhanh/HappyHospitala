import mongoose, { Document, Schema } from "mongoose";

/**
 * Advertisement — Quảng cáo trong ứng dụng
 * [BMC] Revenue Stream: Partnership Revenue (clinics, pharmacies, labs)
 */
export interface IAdvertisement extends Document {
  title: string;
  description?: string;
  imageUrl: string;
  linkUrl?: string;
  advertiser?: string;      // Tên đơn vị quảng cáo
  position: "banner_home" | "popup" | "sidebar" | "banner_booking" | "banner_specialty";
  startDate: Date;
  endDate: Date;
  isActive: boolean;
  clickCount: number;
  impressionCount: number;
  priority: number;         // Thứ tự ưu tiên hiển thị
  targetAudience: "all" | "patient" | "premium";
  budget?: number;          // Ngân sách quảng cáo (VND)
  createdBy?: mongoose.Types.ObjectId;
}

const advertisementSchema = new Schema<IAdvertisement>(
  {
    title: { type: String, required: true },
    description: { type: String },
    imageUrl: { type: String, required: true },
    linkUrl: { type: String },
    advertiser: { type: String },
    position: {
      type: String,
      enum: ["banner_home", "popup", "sidebar", "banner_booking", "banner_specialty"],
      required: true,
    },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    isActive: { type: Boolean, default: true },
    clickCount: { type: Number, default: 0 },
    impressionCount: { type: Number, default: 0 },
    priority: { type: Number, default: 0 },
    targetAudience: { type: String, enum: ["all", "patient", "premium"], default: "all" },
    budget: { type: Number },
    createdBy: { type: Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

advertisementSchema.index({ position: 1, isActive: 1, startDate: 1, endDate: 1 });

const Advertisement = mongoose.model<IAdvertisement>("Advertisement", advertisementSchema);
export default Advertisement;
