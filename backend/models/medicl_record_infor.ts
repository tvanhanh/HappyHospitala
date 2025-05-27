import mongoose, { Schema, Document } from 'mongoose';

export interface IDiabetesRecord extends Document {
  patientName: string;
  email:string;
  doctorName: string;
  departmentName:string;
  examinationDate: String;
  examinationTime: String;
  diagnosis: string;

 
  gender?: string;
  age?: string;

  urea?: string;
  creatinine?: string; 
  hba1c?: string;
  cholesterol?: string;
  triglycerides?: string;
  hdl?: string;
  ldl?: string;
  vldl?: string;
  bmi?: string;

  status: string; // e.g., "Mắc bệnh", "Không mắc bệnh"
}

const DiabetesRecordSchema: Schema = new Schema({
  patientName: { type: String, required: true },
  email: { type: String, required: true },
  examinationDate: { type: String, required: true },
  examinationTime:{type: String, require:true},
  doctorName: { type: String },
  departmentName:{type:String},
  gender: { type: String },
  age: { type: String },
  urea: { type: String },
  creatinine: { type: String },
  hba1c: { type: String },
  cholesterol: { type: String },
  triglycerides: { type: String },
  hdl: { type: String },
  ldl: { type: String },
  vldl: { type: String },
  bmi: { type: String },
  status: { type: String, required: true }
});
const DiabetesRecord = mongoose.model<IDiabetesRecord>('DiabetesRecord', DiabetesRecordSchema);
export default DiabetesRecord ;
