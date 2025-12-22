import mongoose, { Document, Schema, Types } from 'mongoose';

// Định nghĩa interface cho Appointment
export interface IAppointment extends mongoose.Document {
  _id: mongoose.Types.ObjectId;
  patientName: string;
  phone: string;
  reason: string;
  date: string;
  time: string;
  departmentName: string; // Sử dụng Types.ObjectId để tham chiếu đến ObjectId của MongoDB
  doctorName: string;
  status: string;
  email: string;
  createdAt: Date;
}


const AppointmentSchema = new mongoose.Schema<IAppointment>({
  patientName: String,
  phone: String,
  reason: String,
  date: String,
  time: String,
  departmentName: String,
  doctorName: String,
  status: { type: String, default: "pending" },
  email: String,
  createdAt: { type: Date, default: Date.now },
});

// Tạo model với interface
const Appointment = mongoose.model<IAppointment>("Appointment", AppointmentSchema);

export default Appointment;