import mongoose from "mongoose";
import dotenv from "dotenv";
import connectDB from "./config/db";
import Specialty from "./models/Specialty";
import Room from "./models/Room";
import User from "./models/User";
import * as bcrypt from 'bcryptjs';

dotenv.config();

const seedData = async () => {
  try {
    await connectDB();
    console.log("Connected to Database. Clearing old data...");

    // Clear existing collections
    await Specialty.deleteMany();
    await Room.deleteMany();
    // Only delete existing admin accounts to prevent duplicates without deleting regular users/doctors
    await User.deleteMany({ role: "admin" });

    // Seed Specialties
    const specialties = [
      { name: "Da liễu (Dermatology)", description: "Khám và điều trị các bệnh về da", imageUrl: "https://cdn-icons-png.flaticon.com/512/2864/2864303.png" },
      { name: "Tim mạch (Cardiology)", description: "Chăm sóc sức khỏe tim mạch", imageUrl: "https://cdn-icons-png.flaticon.com/512/883/883407.png" },
      { name: "Thần kinh (Neurology)", description: "Chẩn đoán và điều trị bệnh thần kinh", imageUrl: "https://cdn-icons-png.flaticon.com/512/2093/2093077.png" },
      { name: "Nhi khoa (Pediatrics)", description: "Khám bệnh cho trẻ em", imageUrl: "https://cdn-icons-png.flaticon.com/512/2966/2966453.png" },
      { name: "Nha khoa (Dentistry)", description: "Chăm sóc răng miệng", imageUrl: "https://cdn-icons-png.flaticon.com/512/2818/2818366.png" },
      { name: "Mắt (Ophthalmology)", description: "Khám và điều trị các bệnh về mắt", imageUrl: "https://cdn-icons-png.flaticon.com/512/1086/1086478.png" },
    ];
    await Specialty.insertMany(specialties);
    console.log("Specialties seeded!");

    // Seed Rooms
    const rooms = [
      { roomNumber: "Phòng 101", floor: 1, status: "Available" },
      { roomNumber: "Phòng 102", floor: 1, status: "Available" },
      { roomNumber: "Phòng 103", floor: 1, status: "Available" },
      { roomNumber: "Phòng 201", floor: 2, status: "Available" },
      { roomNumber: "Phòng 202", floor: 2, status: "Available" },
      { roomNumber: "Phòng 203", floor: 2, status: "Available" },
      { roomNumber: "Phòng 301", floor: 3, status: "Available" },
      { roomNumber: "Phòng 302", floor: 3, status: "Available" },
      { roomNumber: "Phòng 303", floor: 3, status: "Maintenance" },
      { roomNumber: "Phòng 401", floor: 4, status: "Available" },
    ];
    await Room.insertMany(rooms);
    console.log("Rooms seeded!");

    // Seed Admin User
    const hashedPassword = await bcrypt.hash("password123", 10);
    const adminUser = new User({
      name: "Admin Quản Trị",
      email: "admin@clinic.com",
      password: hashedPassword,
      role: "admin",
      status: "activity",
      profile: {}
    });
    await adminUser.save();
    console.log("Admin seeded!");

    console.log("✅ SEEDING COMPLETE!");
    process.exit(0);
  } catch (error) {
    console.error("❌ ERROR SEEDING:", error);
    process.exit(1);
  }
};

seedData();
