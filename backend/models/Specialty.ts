import mongoose, { Document, Schema } from 'mongoose';

export interface ISpecialty extends Document {
  name: string;
  description?: string;
  imageUrl?: string;
}

const specialtySchema = new Schema<ISpecialty>(
  {
    name: { type: String, required: true, unique: true },
    description: { type: String },
    imageUrl: { type: String },
  },
  { timestamps: true }
);

const Specialty = mongoose.model<ISpecialty>('Specialty', specialtySchema);
export default Specialty;
