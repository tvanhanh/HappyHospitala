const mongoose = require('mongoose');

const DoctorSchema = new mongoose.Schema({
  name: String,
  email: String,
  phone: String,
  departmentId: String,
  specialization: String,
  avatar: String,

});

const Doctor   = mongoose.model("Doctor", DoctorSchema);

export default Doctor;
