import mongoose, { Schema, Document } from 'mongoose';

export interface IDoctorSchedule extends Document {
  doctorId: mongoose.Types.ObjectId;
  roomId: mongoose.Types.ObjectId;
  specialtyId: mongoose.Types.ObjectId;
  date: Date;
  shift: { type: String, enum: ['Sáng', 'Chiều', 'Tối', 'Cả ngày'], required: true }
  timeSlotDuration: number; // MỚI: Khám bao nhiêu phút 1 người (vd: 15)
  maxPatients: number;      // MỚI: Giới hạn tối đa số người trong 1 ca (vd: 16)
  status: 'active' | 'inactive';
}

const DoctorScheduleSchema: Schema = new Schema({
  doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  roomId: { type: Schema.Types.ObjectId, ref: 'Room', required: true },
  specialtyId: { type: Schema.Types.ObjectId, ref: 'Specialty', required: true },
  date: { type: Date, required: true },
  shift: { type: String, enum: ['Sáng', 'Chiều', 'Tối', 'Cả ngày'], required: true },
  
  // Thêm 2 trường này với giá trị mặc định để dễ vận hành
  timeSlotDuration: { type: Number, default: 15 }, 
  maxPatients: { type: Number, default: 16 }, // Sáng 4 tiếng (240p) / 15p = 16 người
  
  status: { type: String, enum: ['active', 'inactive'], default: 'active' }
}, { timestamps: true });

// TẠO CHỈ MỤC CHỐNG TRÙNG LỊCH (Giữ nguyên, rất tốt)
DoctorScheduleSchema.index({ doctorId: 1, date: 1, shift: 1 }, { unique: true });
DoctorScheduleSchema.index({ roomId: 1, date: 1, shift: 1 }, { unique: true });

export default mongoose.model<IDoctorSchedule>('DoctorSchedule', DoctorScheduleSchema);