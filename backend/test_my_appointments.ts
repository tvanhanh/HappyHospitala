import axios from 'axios';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Appointment from './models/Appointment';
import User from './models/User';
import Doctor from './models/Doctor';

dotenv.config();

async function run() {
  try {
    // Connect to database to ensure we can check IDs
    await mongoose.connect(process.env.MONGO_URI as string);
    User.modelName;
    Doctor.modelName;

    // Log in
    const loginRes = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'patient1@gmail.com', // Let's use patient1@gmail.com
      password: '123456' // Seeding password
    });
    
    const token = loginRes.data.token;
    console.log("Logged in successfully. Fetching appointments...");

    // Call getMyProfile
    const profileRes = await axios.get('http://localhost:5000/api/auth/get_profile', {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log("Patient profile email:", profileRes.data.user.email);

    // Call getMyAppointments
    const res = await axios.get('http://localhost:5000/api/appointments/patient', {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log(`API returned ${res.data.data.length} appointments.`);
    if (res.data.data.length > 0) {
      const app = res.data.data[0];
      console.log("Latest appointment JSON:");
      console.log(JSON.stringify(app, null, 2));
    }

    process.exit(0);
  } catch (err: any) {
    console.error("Error running test:", err.response ? err.response.data : err.message);
    process.exit(1);
  }
}

run();
