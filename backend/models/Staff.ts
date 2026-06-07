import mongoose, { Document, Schema } from 'mongoose';

export interface IStaff extends Document {
  userId: mongoose.Types.ObjectId;
  shift?: 'morning' | 'afternoon' | 'night' | 'flexible';
  hireDate?: Date;
  baseSalary?: number;
  contract_urls: string[];
  createdAt: Date;
  updatedAt: Date;
}

const staffSchema = new Schema<IStaff>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    shift: { 
      type: String, 
      enum: ['morning', 'afternoon', 'night', 'flexible'] 
    },
    hireDate: { type: Date },
    baseSalary: { type: Number },
    contract_urls: { type: [String], default: [] }
  },
  { timestamps: true }
);

const Staff = mongoose.model<IStaff>('Staff', staffSchema);
export default Staff;
