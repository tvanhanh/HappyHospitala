import mongoose, { Document, Schema } from 'mongoose';

export interface IService extends Document {
  name: string;
  description: string;
  duration: string;
  price: number;
}

const serviceSchema = new Schema<IService>(
  {
    name: { type: String, required: true, unique: true },
    description: { type: String, required: true },
    duration: { type: String, required: true },
    price: { type: Number, required: true },
  },
  { timestamps: true }
);

const Service = mongoose.model<IService>('Service', serviceSchema);
export default Service;
