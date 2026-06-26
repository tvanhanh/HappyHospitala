import mongoose, { Document, Schema } from "mongoose";

// ================= INTERFACE =================
export interface IAppointment extends Document {
  patient: mongoose.Types.ObjectId;
  doctor: mongoose.Types.ObjectId;

  patientName: string;
  phone: string;

  cccd: String,
  gender?: string;
  address?: string;
  birthDate: Date,
  specialtyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Departments",
  },
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  medicalHistory?: string;
  allergies?: string;

  reason: string;
  date: string;
  time: string;

  imageUrl?: string;

  status: "pending" | "confirmed" | "checked_in" | "in_progress" | "cancelled" | "completed" | "missed";
  appointmentType?: "offline" | "online";
  // Fee & Payment
  originalFee?: number;       // Phí khám gốc (từ Doctor.consultationFee)
  discountAmount?: number;    // Số tiền giảm
  insuranceCoverage?: number; // % BHYT (mặc định 80 = 80%)
  insuranceNumber?: string;   // Số thẻ BHYT
  finalFee?: number;          // Phí thực tế bệnh nhân phải trả
  promotionCode?: string;     // Mã khuyến mãi đã áp dụng
  paymentMethod?: "cash" | "insurance" | "vnpay" | "momo" | "banking";
  isPaid?: boolean;

  // Pre-visit & Digital health workflow locking
  height?: number;
  weight?: number;
  bloodSugar?: number;
  preVisitQuestionnaire?: string;
  preVisitChatHistory?: any;
  isPreVisitCompleted?: boolean;
  isLocked?: boolean;
  diagnosis?: string;
  treatment?: string;
  ePrescription?: string;
}

// ================= SCHEMA =================
const appointmentSchema = new Schema<IAppointment>(
  {
    // ===== RELATION =====
    patient: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    doctor: {
      type: Schema.Types.ObjectId,
      ref: "Doctor",
      required: true,
    },

    // ===== PATIENT INFO SNAPSHOT =====
    patientName: { type: String, required: true },
    phone: { type: String, default: null },
    cccd: { type: String, default: null },
    birthDate: { type: Date, default: null },
    gender: { type: String, default: null },
    address: { type: String, default: null },
    specialtyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Departments",
    },
    medicalHistory: { type: String, default: null },
    allergies: { type: String, default: null },

    // ===== APPOINTMENT INFO =====
    reason: { type: String, default: null },
    date: { type: String, default: null }, // YYYY-MM-DD
    time: { type: String, default: null }, // HH:mm

    // ===== IMAGE =====
    imageUrl: { type: String, default: null },

    // ===== FEE & PAYMENT =====
    originalFee: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },
    insuranceCoverage: { type: Number, default: 0 },  // % BHYT thanh toán
    insuranceNumber: { type: String, default: null },
    finalFee: { type: Number, default: 0 },
    promotionCode: { type: String, default: null },
    paymentMethod: {
      type: String,
      enum: ["cash", "insurance", "vnpay", "momo", "banking"],
      default: "cash",
    },
    isPaid: { type: Boolean, default: false },

    // ===== STATUS =====
    status: {
      type: String,
      enum: [
        "pending",
        "confirmed",
        "checked_in",   // Bệnh nhân đã đến phòng khám
        "in_progress",  // Đang khám
        "cancelled",
        "completed"
      ],
      default: "pending",
    },
    appointmentType: {
      type: String,
      enum: ["offline", "online"],
      default: "offline",
    },

    // ===== PRE-VISIT & DIGITAL HEALTH WORKFLOW =====
    height: { type: Number, default: null },
    weight: { type: Number, default: null },
    bloodSugar: { type: Number, default: null },
    preVisitQuestionnaire: { type: String, default: null },
    preVisitChatHistory: { type: Schema.Types.Mixed, default: null },
    isPreVisitCompleted: { type: Boolean, default: false },
    isLocked: { type: Boolean, default: false },
    diagnosis: { type: String, default: null },
    treatment: { type: String, default: null },
    ePrescription: { type: String, default: null }
  },
  {
    timestamps: true,
  }
);


/**
 * [RACE CONDITION GUARD] — Compound unique index trên (doctor, date, time)
 * để MongoDB tự động từ chối duplicate slot ngay cả khi 2 request đến đồng thời.
 * Chỉ áp dụng khi status KHÔNG phải 'cancelled'.
 * Sử dụng partial filter expression để cho phép nhiều cancelled records.
 */
appointmentSchema.index(
  { doctor: 1, date: 1, time: 1 },
  {
    unique: true,
    partialFilterExpression: {
      status: { $in: ["pending", "confirmed", "checked_in", "in_progress", "completed"] }
    },
    name: "unique_active_slot"
  }
);

// ================= MODEL =================
const Appointment = mongoose.model<IAppointment>(
  "Appointment",
  appointmentSchema
);

export default Appointment;