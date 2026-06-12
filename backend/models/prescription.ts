import { Schema, model, Document } from 'mongoose';
export type PrescriptionStatus = 'pending' | 'completed' | 'cancelled'|'paid';
export interface IPrescribedMedicine {
  id: string; 
  name: string;
  quantity: string;
  usage: string;
  sellingPrice: number;
  unit: string;
}

// Interface chính cho Đơn thuốc (Kế thừa Document của Mongoose)
export interface IPrescription extends Document {
  appointmentId: string;
  diagnosis: string;
  patientId: string;
  patientName: string;
  patientPhone?: string | null;    
  birthDate?: string | null;      
  gender?: string | null;          
  healthInsurance?: string | null; 
  medicines: IPrescribedMedicine[];
  status :PrescriptionStatus;
  doctorId: string;
  doctorName: string;
  createdAt: Date;
}

// Schema dành cho danh sách thuốc (Không tạo _id riêng để tránh rác DB)
const PrescribedMedicineSchema = new Schema<IPrescribedMedicine>({
  id: { type: String, required: true },
  name: { type: String, required: true },
  quantity: { type: String, required: true },
  usage: { type: String, required: true },
  sellingPrice: { type: Number, required: true },
  unit: { type: String, required: true }

}, { _id: false });

// Schema chính cho Prescription
const PrescriptionSchema = new Schema<IPrescription>({
  appointmentId: { type: String, required: true },
  diagnosis: { type: String, required: true },
  patientId: { type: String, required: true },
  patientName: { type: String, required: true },
  
  patientPhone: { type: String, default: null },
  birthDate: { type: String, default: null },
  gender: { type: String, default: null },
  healthInsurance: { type: String, default: null },
  
  medicines: { type: [PrescribedMedicineSchema], required: true },
status: { 
    type: String, 
    enum: ['pending', 'completed', 'cancelled', 'paid'], 
    default: 'pending' 
  },
  doctorId: { type: String, required: true },
  doctorName: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

export const PrescriptionModel = model<IPrescription>('Prescription', PrescriptionSchema);