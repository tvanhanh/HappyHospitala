import mongoose, { Document, Schema } from "mongoose";

export interface IMedicineCategory extends Document {
  categoryname: string;
  description?: string;
}

const MedicineCategorySchema = new Schema<IMedicineCategory>({
  categoryname: { type: String, required: true },
  description: { type: String },
});

// Đặt tên collection trong MongoDB là "medicine_categories" để phân biệt rõ ràng
const MedicineCategories = mongoose.model<IMedicineCategory>("MedicineCategories", MedicineCategorySchema, "medicine_categories");

export default MedicineCategories;