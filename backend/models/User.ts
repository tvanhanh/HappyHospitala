import mongoose, { Document, Schema } from 'mongoose';

export interface IUser extends Document {
  email: string;
  password?: string;
  role: 'admin' | 'doctor' | 'patient' | 'receptionist' | 'cashier' | 'pharmacy';
  status: string;
  isDeleted: boolean;
  fullName?: string;
  phoneNumber?: string;
  cccd?: string;
  dateOfBirth?: Date;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  avatar?: string;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String }, // Optional if using OAuth/SSO
    role: { 
      type: String, 
      enum: ['admin', 'doctor', 'patient', 'receptionist', 'cashier', 'pharmacy'], 
      required: true 
    },
    status: { type: String, default: 'activity' },
    isDeleted: { type: Boolean, default: false },
    fullName: { type: String, trim: true },
    phoneNumber: { type: String, trim: true },
    cccd: { type: String, trim: true },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ['male', 'female', 'other'] },
    address: { type: String, trim: true },
    avatar: { type: String }
  },
  { timestamps: true }
);

const User = mongoose.model<IUser>('User', userSchema);
export default User;
