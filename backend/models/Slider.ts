import mongoose, { Document, Schema } from 'mongoose';

export interface ISlider extends Document {
  imageUrl: string;
  title?: string;
  subtitle?: string;
  isActive: boolean;
}

const sliderSchema = new Schema<ISlider>(
  {
    imageUrl: { type: String, required: true },
    title: { type: String, default: '' },
    subtitle: { type: String, default: '' },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export default mongoose.model<ISlider>('Slider', sliderSchema);
