import mongoose, { Document } from 'mongoose';

export interface IDepartment extends Document {
  _id: string;
  departmentName: string;
  description?: string;
}

const DepartmentSchema = new mongoose.Schema({
  departmentName: { type: String, required: true },
  description: { type: String },

});

const Departments  = mongoose.model<IDepartment>("Departments", DepartmentSchema);

export default Departments;
