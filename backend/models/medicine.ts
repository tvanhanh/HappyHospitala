import mongoose, { Document, Schema } from 'mongoose';

export interface IMedicine extends Document {
  medicineCode: string;
  name: string;
  activeIngredient: string;
  categoryId: mongoose.Types.ObjectId | string;
  routeOfAdministration: string;
  unit: string;
  stockLevel: number;
  reorderLevel: number;
  unitPrice: number;
  expiryDate: Date;
  manufacturer: string;
  createdAt: Date;
  updatedAt: Date;
}

const medicineSchema = new Schema<IMedicine>(
  {
    medicineCode: { type: String, required: true, unique: true, uppercase: true, trim: true },
    name: { type: String, required: true, trim: true },
    activeIngredient: { type: String, required: true, trim: true },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', required: true },
    routeOfAdministration: { type: String, required: true, trim: true },
    unit: { type: String, required: true, trim: true },
    stockLevel: { type: Number, required: true, default: 0 },
    reorderLevel: { type: Number, required: true, default: 10 },
    unitPrice: { type: Number, required: true, default: 0 },
    expiryDate: { type: Date, required: true },
    manufacturer: { type: String, required: true, trim: true }
  },
  { timestamps: true }
);

const Medicine = mongoose.model<IMedicine>('Medicine', medicineSchema);
export default Medicine;
