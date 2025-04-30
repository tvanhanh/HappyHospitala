import mongoose, { Document } from 'mongoose';

// Định nghĩa interface cho Doctor
export interface IDoctor extends Document {
  _id: mongoose.Types.ObjectId;
  doctorName: string;
  email?: string;
  phone?: string;
  address?: string;
  departmentName: mongoose.Types.ObjectId; // Đây là ID của phòng ban
  specialization?: string;
  avatar?: string;
}

// Định nghĩa schema Doctor
const doctorSchema = new mongoose.Schema({
  doctorName: { type: String, required: true },
  email: { type: String },
  phone: { type: String },
  address: { type: String },
  departmentName: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
  specialization: { type: String },
  avatar: { type: String },
});

const Doctor = mongoose.model<IDoctor>('Doctor', doctorSchema);
export default Doctor;