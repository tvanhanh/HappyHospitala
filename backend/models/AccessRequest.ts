import { Schema, model } from 'mongoose';

const AccessRequestSchema = new Schema({
  requestId: { type: String, required: true, unique: true },
  patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  patientName: { type: String, default: "Bệnh nhân hệ thống" }, 
  doctorId: { type: String, required: true },
  reason: { type: String, required: true }, 
  requestedRecordId: { type: String, required: true },  
  status: { 
    type: String, 
    enum: ["pending", "approved", "rejected"], 
    default: "pending" 
  },
  time: { type: String },
  createdAt: { type: Date, default: Date.now } 
}, { 
  timestamps: true
});

export const AccessRequest = model("AccessRequest", AccessRequestSchema);