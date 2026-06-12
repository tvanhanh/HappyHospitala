import mongoose, { Document, Schema } from 'mongoose';

export interface IDoctor extends Document {
  userId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  roomId?: mongoose.Types.ObjectId; // Liên kết tới Phòng khám vật lý
  specialty?: string;              // Chuyên môn sâu (nếu cần)
  experience_years?: number;
  education: Array<{
    degree: string;
    university: string;
    year: number;
  }>;
  certifications_urls: string[];
  bio?: string;
  consultationFee?: number;
  profile_status: 'HIDDEN' | 'PENDING_APPROVAL' | 'ACTIVE' | 'REJECTED';
  rejection_reason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const doctorSchema = new Schema<IDoctor>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Departments' },
    roomId: { type: Schema.Types.ObjectId, ref: 'Room' }, // Thêm tham chiếu đến bảng Phòng
    specialty: { type: String }, // Lưu tên chuyên môn sâu (VD: Tim mạch, Hô hấp...)
    experience_years: { type: Number, default: 0 },
    education: [
      {
        degree: { type: String, required: true },
        university: { type: String, required: true },
        year: { type: Number, required: true }
      }
    ],
    certifications_urls: { type: [String], default: [] },
    bio: { type: String },
    consultationFee: { type: Number, default: 0 },
    profile_status: {
      type: String,
      enum: ['HIDDEN', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED'],
      default: 'HIDDEN'
    },
    rejection_reason: { type: String }
  },
  { timestamps: true }
);

// Tạo Index để tối ưu truy vấn
doctorSchema.index({ departmentId: 1, profile_status: 1 });

const Doctor = mongoose.model<IDoctor>('Doctor', doctorSchema);
export default Doctor;