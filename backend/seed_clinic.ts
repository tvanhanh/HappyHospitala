import mongoose from "mongoose";
import dotenv from "dotenv";
import connectDB from "./config/db";
import bcrypt from "bcrypt";

import User from "./models/User";
import Doctor from "./models/Doctor";
import Department from "./models/Departments";
import Room from "./models/Room";
import Specialty from "./models/Specialty";
import Promotion from "./models/MedicalPost";
import { PremiumPackage } from "./models/PremiumPackage";
import Advertisement from "./models/Advertisement";

dotenv.config();

const seedData = async () => {
  try {
    await connectDB();
    console.log("MongoDB Connected. Starting Seed (SAFE MODE - NO DELETE)...");

    // ── 1. SAFE CLEAN UP - chỉ xóa các collection mới, KHÔNG xóa User/Doctor/Patient ──
    await Promotion.deleteMany({});
    await PremiumPackage.deleteMany({});
    await Advertisement.deleteMany({});
    console.log("New collections cleared safely (Users/Doctors/Patients preserved).");

    const defaultPassword = await bcrypt.hash("123456", 10);

    // ── 1.5. UPSERT DEV ACCOUNTS ──
    const avatarUrl = "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500&h=500&fit=crop";
    const docAvatarUrl = "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500&h=500&fit=crop";

    const accounts = [
      { email: "admin@gmail.com", name: "Quản Trị Viên", role: "admin", phone: "0901234567", avatar: avatarUrl },
      { email: "doctor1@clinic.com", name: "BS. Trần Văn Hạnh", role: "doctor", phone: "0912345678", avatar: docAvatarUrl },
      { email: "patient1@gmail.com", name: "Nguyễn Văn Bệnh Nhân", role: "patient", phone: "0923456789", avatar: avatarUrl },
      { email: "receptionist@gmail.com", name: "Lê Thị Lễ Tân", role: "receptionist", phone: "0934567890", avatar: avatarUrl },
      { email: "cashier@gmail.com", name: "Phạm Thu Ngân", role: "cashier", phone: "0945678901", avatar: avatarUrl },
      { email: "pharmacist@gmail.com", name: "Vũ Dược Sĩ", role: "pharmacy", phone: "0956789012", avatar: avatarUrl },
    ];

    for (const acc of accounts) {
      let user = await User.findOne({ email: acc.email });
      if (!user) {
        user = await User.create({
          name: acc.name,
          email: acc.email,
          password: defaultPassword,
          role: acc.role,
          profile: { phone: acc.phone, avatar: acc.avatar },
        });
      }

      // If doctor, ensure Doctor record exists
      if (acc.role === "doctor") {
        const docRecord = await Doctor.findOne({ userId: user._id });
        if (!docRecord) {
          await Doctor.create({
            userId: user._id,
            doctorName: acc.name,
            email: acc.email,
            phone: acc.phone,
            avatar: acc.avatar,
            specialization: "Nội khoa",
            consultationFee: 150000,
          });
        }
      }
    }
    console.log("Dev accounts upserted successfully.");

    // ── 2. PROMOTIONS ──
    await Promotion.insertMany([
      { code: "WELCOME", name: "Giảm giá khách mới", discountType: "percent", discountValue: 50, maxDiscount: 100000, validFrom: new Date(), validTo: new Date(Date.now() + 30*86400000), applicableFor: "new_patient" },
      { code: "BHYT", name: "Bảo hiểm y tế", discountType: "percent", discountValue: 80, validFrom: new Date(), validTo: new Date(Date.now() + 365*86400000), applicableFor: "insurance" },
    ]);

    // ── 8. PREMIUM PACKAGES ──
    await PremiumPackage.insertMany([
      { name: "Silver", slug: "silver", price: 99000, durationDays: 30, features: ["Ưu tiên xếp hàng", "Hỗ trợ 24/7"], priorityBooking: true, color: "#9E9E9E", icon: "stars" },
      { name: "Gold", slug: "gold", price: 299000, durationDays: 30, features: ["Tất cả tính năng Silver", "Chẩn đoán AI miễn phí", "Khám online"], priorityBooking: true, aiDiagnosis: true, color: "#FFD700", icon: "workspace_premium" },
    ]);

    // ── 9. ADVERTISEMENTS ──
    await Advertisement.insertMany([
      { title: "Khám sức khỏe tổng quát", imageUrl: "https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg", position: "banner_home", startDate: new Date(), endDate: new Date(Date.now() + 30*86400000), isActive: true },
      { title: "Gói xét nghiệm gan", imageUrl: "https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg", position: "banner_booking", startDate: new Date(), endDate: new Date(Date.now() + 30*86400000), isActive: true },
    ]);

    console.log("Seed Completed Successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Seed Failed:", error);
    process.exit(1);
  }
};

seedData();
