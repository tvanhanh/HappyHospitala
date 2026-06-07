import mongoose, { Document, Schema } from 'mongoose';

export interface IPatient extends Document {
  userId: mongoose.Types.ObjectId;
  healthInsuranceCode?: string;
  bloodType?: string;
  medicalHistory: string[];
  allergies: string[];
  chronicDiseases: string[];
  emergencyContact?: {
    name: string;
    phone: string;
    relationship: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const patientSchema = new Schema<IPatient>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    healthInsuranceCode: { type: String, trim: true },
    bloodType: { type: String, trim: true },
    medicalHistory: { type: [String], default: [] },
    allergies: { type: [String], default: [] },
    chronicDiseases: { type: [String], default: [] },
    emergencyContact: {
      name: { type: String, trim: true },
      phone: { type: String, trim: true },
      relationship: { type: String, trim: true }
    }
  },
  { timestamps: true }
);

const Patient = mongoose.model<IPatient>('Patient', patientSchema);
export default Patient;
