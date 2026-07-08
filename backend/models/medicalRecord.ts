import mongoose from "mongoose";

const MedicalRecordSchema = new mongoose.Schema({
  appointmentId: { type: String, required: true },
  patientId: {
    type: String,
    required: true,
  },
  doctorId: {
    type: String,
    required: true,
  },
  patientName: {
    type: String,
    required: true,
  },
  doctorName: {
    type: String,
  },
  patientEmail: {
    type: String,
  },
  visitDate: {
    type: Date,
    required: true,
  },
  metrics: {
    urea: { type: Number },
    creatinine: { type: Number },
    hba1c: { type: Number },
    cholesterol: { type: Number },
    triglycerides: { type: Number },
    hdl: { type: Number },
    ldl: { type: Number },
    vldl: { type: Number },
    bmi: { type: Number },
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
  ipfsHash:{
    type: String,
  },
  blockchainTx: {
    type: String,
    default: null,
  },
  blockchainNetwork: {
    type: String,
  },
  blockNumber: {
    type: Number,
  },
  blockchainIndex: {
    type: Number,
    required: false,
  },
  // Lịch sử truy cập (ai xem, lúc nào)
  accessLogs: [
    {
      viewerId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
      role: String, 
      time: Date,
    },
  ],
  allowedStaffs: {
    type: [String],
    default: function (this: any): string[] {
      return [this.doctorId];
    },
  },
pendingRequests: {
    type: [String],
    default: []
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.model("MedicalRecord", MedicalRecordSchema);