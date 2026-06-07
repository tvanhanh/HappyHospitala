import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import connectDB from './config/db';
import User from './models/User';
import Patient from './models/Patient';

dotenv.config();

const seedPatients = async () => {
  try {
    await connectDB();
    console.log("MongoDB Connected. Starting Patient Seeding...");

    // Remove old patients first if any (optional, but good for fresh test data)
    // We will just upsert based on email
    
    const patientsData = [
      {
        email: "patient1@clinic.com",
        name: "Nguyễn Văn An",
        phone: "0901111111",
        address: "123 Lê Lợi, Q1, TP.HCM",
        avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1974&auto=format&fit=crop",
        identityCard: "079090000001",
        healthInsurance: "DN4790000123456",
        dateOfBirth: "1990-01-01",
        gender: "Nam",
        bloodType: "O+",
        allergies: ["Penicillin", "Hải sản"],
        chronicDiseases: ["Dạ dày"],
        emergencyContact: { name: "Nguyễn Thị Bình", phone: "0902222222", relationship: "Vợ" },
        walletAddress: "0x1234567890abcdef1234567890abcdef12345678",
      },
      {
        email: "patient2@clinic.com",
        name: "Trần Thị Bé",
        phone: "0903333333",
        address: "456 Nguyễn Huệ, Q1, TP.HCM",
        avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=2070&auto=format&fit=crop",
        identityCard: "079090000002",
        healthInsurance: "DN4790000123457",
        dateOfBirth: "1985-05-15",
        gender: "Nữ",
        bloodType: "A+",
        allergies: ["Phấn hoa"],
        chronicDiseases: [],
        emergencyContact: { name: "Trần Văn Cháu", phone: "0904444444", relationship: "Con" },
        walletAddress: "0xabcdef1234567890abcdef1234567890abcdef12",
      },
      {
        email: "patient3@clinic.com",
        name: "Lê Văn Cường",
        phone: "0905555555",
        address: "789 Điện Biên Phủ, Bình Thạnh, TP.HCM",
        avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1974&auto=format&fit=crop",
        identityCard: "079090000003",
        healthInsurance: "DN4790000123458",
        dateOfBirth: "1978-08-20",
        gender: "Nam",
        bloodType: "B+",
        allergies: [],
        chronicDiseases: ["Tiểu đường", "Huyết áp cao"],
        emergencyContact: { name: "Lê Thị Dung", phone: "0906666666", relationship: "Vợ" },
        walletAddress: "0x7890abcdef1234567890abcdef1234567890abcd",
      },
      {
        email: "patient4@clinic.com",
        name: "Phạm Thị Dung",
        phone: "0907777777",
        address: "321 Cách Mạng Tháng 8, Q10, TP.HCM",
        avatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1976&auto=format&fit=crop",
        identityCard: "079090000004",
        healthInsurance: "DN4790000123459",
        dateOfBirth: "1995-12-10",
        gender: "Nữ",
        bloodType: "AB+",
        allergies: ["Lông chó mèo"],
        chronicDiseases: ["Hen suyễn"],
        emergencyContact: { name: "Phạm Văn Em", phone: "0908888888", relationship: "Anh trai" },
        walletAddress: "0x34567890abcdef1234567890abcdef1234567890",
      },
      {
        email: "patient5@clinic.com",
        name: "Hoàng Văn Em",
        phone: "0909999999",
        address: "654 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM",
        avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=2070&auto=format&fit=crop",
        identityCard: "079090000005",
        healthInsurance: "DN4790000123460",
        dateOfBirth: "1982-03-25",
        gender: "Nam",
        bloodType: "O-",
        allergies: [],
        chronicDiseases: [],
        emergencyContact: { name: "Hoàng Thị Phượng", phone: "0900000001", relationship: "Chị gái" },
        walletAddress: "0xdef1234567890abcdef1234567890abcdef12345",
      }
    ];

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash("123456", salt);

    for (const p of patientsData) {
      let user = await User.findOne({ email: p.email });
      if (!user) {
        user = new User({
          name: p.name,
          email: p.email,
          password: hashedPassword,
          role: "patient",
          status: "activity",
          profile: {
            phone: p.phone,
            address: p.address,
            avatar: p.avatar,
            gender: p.gender,
            dateOfBirth: p.dateOfBirth,
          }
        });
        await user.save();
        console.log(`✅ Created User: ${p.email}`);
      } else {
        console.log(`⚠️ User already exists: ${p.email}`);
      }

      let patient = await Patient.findOne({ userId: user._id });
      if (!patient) {
        patient = new Patient({
          userId: user._id,
          identityCard: p.identityCard,
          healthInsurance: p.healthInsurance,
          dateOfBirth: p.dateOfBirth,
          gender: p.gender,
          bloodType: p.bloodType,
          allergies: p.allergies,
          chronicDiseases: p.chronicDiseases,
          emergencyContact: p.emergencyContact,
          walletAddress: p.walletAddress,
        });
        await patient.save();
        console.log(`✅ Created Patient Profile for: ${p.email}`);
      } else {
        await Patient.updateOne(
          { userId: user._id },
          {
            $set: {
              identityCard: p.identityCard,
              healthInsurance: p.healthInsurance,
              dateOfBirth: p.dateOfBirth,
              gender: p.gender,
              bloodType: p.bloodType,
              allergies: p.allergies,
              chronicDiseases: p.chronicDiseases,
              emergencyContact: p.emergencyContact,
              walletAddress: p.walletAddress,
            }
          }
        );
        console.log(`✅ Updated Patient Profile for: ${p.email}`);
      }
    }

    console.log("✨ Seeding Patients Completed Successfully!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error seeding patients:", error);
    process.exit(1);
  }
};

seedPatients();
