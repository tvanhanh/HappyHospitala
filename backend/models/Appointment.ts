import mongoose, { Document, Schema } from "mongoose";

// ================= INTERFACE =================
export interface IAppointment extends Document {
  patient: mongoose.Types.ObjectId;
  doctor: mongoose.Types.ObjectId;

  patientName: string;
  phone: string;
  gender?: string;
  address?: string;

  medicalHistory?: string;
  allergies?: string;

  reason: string;
  date: string;
  time: string;

  imageUrl?: string;

  status: "pending" | "confirmed" | "cancelled" | "completed";
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
      ref: "User",
      required: true,
    },

    // ===== PATIENT INFO SNAPSHOT =====
    patientName: { type: String, required: true },
    phone: { type: String, required: true },
    gender: { type: String },
    address: { type: String },

    medicalHistory: { type: String },
    allergies: { type: String },

    // ===== APPOINTMENT INFO =====
    reason: { type: String, required: true },
    date: { type: String, required: true }, // YYYY-MM-DD
    time: { type: String, required: true }, // HH:mm

    // ===== IMAGE =====
    imageUrl: { type: String }, // ảnh bệnh (Cloudinary)

    // ===== STATUS =====
  status: {
  type: String,
  enum: [
    "pending",
    "confirmed",
    "in_progress", // 🔥 thêm cái này
    "cancelled",
    "completed"
  ],
  default: "pending",
}
  },
  {
    timestamps: true, // createdAt + updatedAt
  }
);

// ================= MODEL =================
const Appointment = mongoose.model<IAppointment>(
  "Appointment",
  appointmentSchema
);

export default Appointment;