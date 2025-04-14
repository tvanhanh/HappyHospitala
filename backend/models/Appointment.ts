const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
  name: String,
  phone: String,
  date: Date,
  status: { type: String, default: 'pending' }, 
});

module.exports = mongoose.model('Appointment', AppointmentSchema);
