const mongoose = require('mongoose');

const DepartmentSchema = new mongoose.Schema({
  departmentName: String,
  description :String,

});

const Departments  = mongoose.model("Departments", DepartmentSchema);

export default Departments;
