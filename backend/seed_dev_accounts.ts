import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import User from './models/User';
import Doctor from './models/Doctor';
import dotenv from 'dotenv';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/smart_clinic';

const seedDevAccounts = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('MongoDB connected for seeding dev accounts...');

    const hashedPassword = await bcrypt.hash('1', 10);

    const accounts = [
      { name: 'Dev Admin', email: 'a', password: hashedPassword, role: 'admin', status: 'activity' },
      { name: 'Dev Receptionist', email: 'r', password: hashedPassword, role: 'receptionist', status: 'activity' },
      { name: 'Dev Cashier', email: 'c', password: hashedPassword, role: 'cashier', status: 'activity' },
      { name: 'Dev Doctor', email: 'd', password: hashedPassword, role: 'doctor', status: 'activity' },
      { name: 'Dev Patient', email: 'p', password: hashedPassword, role: 'patient', status: 'activity' },
    ];

    for (const acc of accounts) {
      // Upsert user
      let user = await User.findOne({ email: acc.email });
      if (!user) {
        user = new User(acc);
        await user.save();
        console.log(`Created User: ${acc.email} (Role: ${acc.role})`);

        // Create linked profiles for Doctor/Patient
        if (acc.role === 'doctor') {
          const doc = new Doctor({ _id: user._id, doctorName: acc.name, email: acc.email });
          await doc.save();
          console.log(`Created Doctor Profile for ${acc.email}`);
        }
      } else {
        user.password = hashedPassword; // reset to '1' just in case
        await user.save();
        console.log(`Updated User: ${acc.email} (Role: ${acc.role})`);
      }
    }

    console.log('--- SEEDING SUCCESSFUL ---');
    console.log('Login credentials:');
    console.log('Admin:        Email: a | Pass: 1');
    console.log('Receptionist: Email: r | Pass: 1');
    console.log('Cashier:      Email: c | Pass: 1');
    console.log('Doctor:       Email: d | Pass: 1');
    console.log('Patient:      Email: p | Pass: 1');
    
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
};

seedDevAccounts();
