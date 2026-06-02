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
 departmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
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

  status: "pending" | "confirmed" | "cancelled" | "completed";
}

// ================= SCHEMA =================
const appointmentSchema = new Schema<IAppointment>(
  {
    // ===== RELATION =====
    patient: {
      type: Schema.Types.ObjectId,
      ref: "User",
     default: null,
    },

    doctor: {
      type: Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    // ===== PATIENT INFO SNAPSHOT =====
    patientName: { type: String, required: true },
    phone: { type: String, default: null },
    cccd: { type: String, default: null },
    birthDate: { type: Date, default: null },
    gender: { type: String,default: null },
    address: { type: String, default: null },
    departmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
    },
    medicalHistory: { type: String, default: null },
    allergies: { type: String, default: null },

    // ===== APPOINTMENT INFO =====
    reason: { type: String, default: null },
    date: { type: String, default: null }, // YYYY-MM-DD
    time: { type: String, default: null }, // HH:mm

    // ===== IMAGE =====
    imageUrl: { type: String, default: null }, // ảnh bệnh (Cloudinary)

    // ===== STATUS =====
  status: {
  type: String,
  enum: [
    "pending",
    "confirmed",
    "in_progress", 
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