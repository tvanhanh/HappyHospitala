import { Schema, model } from "mongoose";
const MedicalRecordSchema = new Schema({
  patientId: String,
  doctorId: String,
  content: String,        // Dữ liệu mã hóa
  ipfsCid: String,        // CID file trên IPFS
  ehrHash: String,        // Hash dữ liệu đã mã hóa
  blockchainTxId: String, // Transaction hash, xác thực trên blockchain
  createdAt: { type: Date, default: Date.now },
});
export default model("MedicalRecord", MedicalRecordSchema);
