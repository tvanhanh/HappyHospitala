import mongoose from "mongoose";

const MedicalRecordSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Patient",
    required: true,
  },

  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Doctor",
    required: true,
  },

  visitDate: {
    type: Date,
    required: true,
  },

  symptoms: {
    type: String,
    required: true,
  },

  diagnosis: {
    type: String,
    required: true,
  },

  treatment: {
    type: String,
    required: true,
  },

  attachments: [
    {
      type: String, // URL ảnh/X-ray/PDF upload lên storage
    },
  ],

  pdfUrl: {
    type: String, // PDF tự generate sau khi lưu
  },

  // Hash của file PDF để lưu lên blockchain
  pdfHash: {
    type: String,
  },

  // TxHash của blockchain (transaction hash)
  blockchainTx: {
    type: String,
  },

  // Lịch sử truy cập (ai xem, lúc nào)
  accessLogs: [
    {
      viewerId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
      role: String, // bác sĩ / nhân viên / bệnh nhân
      time: Date,
    },
  ],

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.model("MedicalRecord", MedicalRecordSchema);
