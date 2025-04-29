const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
  patientName: String,
  phone: String,
  reason: String, 
  date: String,
  time: String,
  status: { type: String, default: "pending" },
  email: String,
});

const Appointment = mongoose.model("Appointment", AppointmentSchema);

export default Appointment;
