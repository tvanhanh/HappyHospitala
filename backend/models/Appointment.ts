const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
  patientName: String,
  phone: String,
  reason: String, 
  date: String,
  time: String,
  departmentName: { type: mongoose.Schema.Types.ObjectId, ref: 'Department', required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: true },
  status: { type: String, default: "pending" },
  email: String,
  createdAt: { type: Date, default: Date.now },
});

const Appointment = mongoose.model("Appointment", AppointmentSchema);

export default Appointment;
