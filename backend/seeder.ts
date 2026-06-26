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

    // // Clear existing collections
    await Specialty.deleteMany();
    await Room.deleteMany();


    // Seed Specialties
    const specialties = [
      { name: "Da liễu", description: "Khám và điều trị các bệnh về da", imageUrl: "https://cdn-icons-png.flaticon.com/128/10154/10154433.png" },
      { name: "Tim mạch", description: "Chăm sóc sức khỏe tim mạch", imageUrl: "https://cdn-icons-png.flaticon.com/128/10154/10154414.png" },
      { name: "Thần kinh", description: "Chẩn đoán và điều trị bệnh thần kinh", imageUrl: "https://cdn-icons-png.flaticon.com/128/2491/2491401.png" },
      { name: "Nhi khoa", description: "Khám bệnh cho trẻ em", imageUrl: "https://cdn-icons-png.flaticon.com/128/5996/5996306.png" },
      { name: "Nha khoa", description: "Chăm sóc răng miệng", imageUrl: "https://cdn-icons-png.flaticon.com/128/2818/2818366.png" },
      { name: "Mắt", description: "Khám và điều trị các bệnh về mắt", imageUrl: "https://cdn-icons-png.flaticon.com/128/1694/1694439.png" },
       { name: "Nội tiết", description: "Khám và điều trị các bệnh về mắt", imageUrl: "https://cdn-icons-png.flaticon.com/128/4785/4785772.png" },
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
    const hashedPassword = await bcrypt.hash("123456", 10);
    const adminUser = new User({
      name: "Admin Quản Trị",
      email: "admin@gmail.com",
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
