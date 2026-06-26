import mongoose, { Document, Schema } from 'mongoose';

export interface IDoctor extends Document {
  userId: mongoose.Types.ObjectId;
  specialtyId?: mongoose.Types.ObjectId; // ✅ Đổi thành specialtyId (Chuyên khoa gốc)
  // ❌ Đã xóa roomId (Vì Phòng khám sẽ được phân công linh hoạt qua bảng DoctorSchedule)
  specialty?: string;              // Tên chuyên môn sâu viết tay (VD: Tim mạch nhi, Da liễu thẩm mỹ...)
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
    specialtyId: { type: Schema.Types.ObjectId, ref: 'Specialty' }, // ✅ Trỏ đúng về bảng Specialty
    specialty: { type: String }, 
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

// ✅ Cập nhật lại Index để tối ưu truy vấn theo specialtyId mới
doctorSchema.index({ specialtyId: 1, profile_status: 1 });

const Doctor = mongoose.model<IDoctor>('Doctor', doctorSchema);
export default Doctor;