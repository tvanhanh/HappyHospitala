import mongoose from "mongoose";
import dotenv from "dotenv";
import connectDB from "./config/db";
import Doctor from "./models/Doctor";
import User from "./models/User";
import Room from "./models/Room";
import RoomAssignment from "./models/RoomAssignment";

dotenv.config();

const updateDoctors = async () => {
  try {
    await connectDB();
    console.log("MongoDB Connected. Starting Doctor Enrichment...");

    const enrichments = [
      {
        email: "doctor1@clinic.com",
        avatar: "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2070&auto=format&fit=crop",
        dateOfBirth: "1980-05-15",
        gender: "Nam",
        address: "123 Nguyễn Văn Linh, Quận 7, TP.HCM",
        bio: "Bác sĩ chuyên khoa I với hơn 15 năm kinh nghiệm trong lĩnh vực Nội khoa. Từng công tác tại các bệnh viện lớn hàng đầu.",
        licenseNumber: "CCHN-001234",
        experienceYears: 15,
        education: ["Đại học Y Dược TP.HCM", "Tu nghiệp tại Pháp"]
      },
      {
        email: "doctor2@clinic.com",
        avatar: "https://images.unsplash.com/photo-1594824432263-8f06f52e5058?q=80&w=2070&auto=format&fit=crop",
        dateOfBirth: "1985-08-22",
        gender: "Nữ",
        address: "45 Lê Lợi, Quận 1, TP.HCM",
        bio: "Chuyên gia về Da liễu với tâm huyết mang lại làn da khỏe đẹp cho mọi người.",
        licenseNumber: "CCHN-005678",
        experienceYears: 10,
        education: ["Đại học Y Khoa Phạm Ngọc Thạch", "Đào tạo chuyên sâu tại Hàn Quốc"]
      },
      {
        email: "doctor3@clinic.com",
        avatar: "https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=2064&auto=format&fit=crop",
        dateOfBirth: "1978-11-03",
        gender: "Nam",
        address: "89 Trần Hưng Đạo, Quận 5, TP.HCM",
        bio: "Bác sĩ Ngoại khoa với nhiều ca phẫu thuật phức tạp thành công. Luôn đặt y đức lên hàng đầu.",
        licenseNumber: "CCHN-009012",
        experienceYears: 20,
        education: ["Học viện Quân Y", "Thạc sĩ Y khoa Đại học Y Hà Nội"]
      },
      {
        email: "doctor4@clinic.com",
        avatar: "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=2070&auto=format&fit=crop",
        dateOfBirth: "1990-02-18",
        gender: "Nữ",
        address: "12 Võ Văn Ngân, TP Thủ Đức",
        bio: "Bác sĩ Nhi khoa yêu trẻ, dày dặn kinh nghiệm trong điều trị các bệnh lý trẻ em và tư vấn dinh dưỡng.",
        licenseNumber: "CCHN-003456",
        experienceYears: 8,
        education: ["Đại học Y Dược TP.HCM", "Chứng chỉ Nhi khoa Quốc tế"]
      },
      {
        email: "doctor5@clinic.com",
        avatar: "https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=2070&auto=format&fit=crop",
        dateOfBirth: "1982-09-30",
        gender: "Nam",
        address: "78 Nguyễn Trãi, Thanh Xuân, Hà Nội",
        bio: "Bác sĩ Tai Mũi Họng giàu kinh nghiệm. Từng chữa trị thành công nhiều ca bệnh lý khó, mạn tính.",
        licenseNumber: "CCHN-007890",
        experienceYears: 12,
        education: ["Đại học Y Hà Nội", "Chuyên khoa I Tai Mũi Họng"]
      },
      {
        email: "doctor6@clinic.com",
        avatar: "https://images.unsplash.com/photo-1651008376811-b90baee60c1f?q=80&w=1974&auto=format&fit=crop",
        dateOfBirth: "1988-12-12",
        gender: "Nữ",
        address: "56 Nguyễn Đình Chiểu, Quận 3, TP.HCM",
        bio: "Bác sĩ Răng Hàm Mặt, chuyên sâu về chỉnh nha và Implant với kỹ thuật tiên tiến nhất.",
        licenseNumber: "CCHN-002468",
        experienceYears: 11,
        education: ["Đại học Y Dược TP.HCM", "Tu nghiệp Implant tại Mỹ"]
      }
    ];

    for (const doc of enrichments) {
      // Update Doctor collection
      const existingDoctor = await Doctor.findOne({ email: doc.email });
      if (existingDoctor) {
        await Doctor.updateOne(
          { email: doc.email },
          { $set: {
              avatar: doc.avatar,
              dateOfBirth: doc.dateOfBirth,
              gender: doc.gender,
              address: doc.address,
              bio: doc.bio,
              licenseNumber: doc.licenseNumber,
              experienceYears: doc.experienceYears,
              education: doc.education
            }
          }
        );
        console.log(`✅ Enriched doctor: ${doc.email}`);

        // Update User collection avatar as well so the frontend shows the avatar seamlessly
        await User.updateOne(
          { email: doc.email },
          { $set: { "profile.avatar": doc.avatar } }
        );
      } else {
        console.log(`⚠️ Doctor not found for email: ${doc.email}, skipping. If they don't exist yet, run the seed script first.`);
      }
    }

    // --- ASSIGN DOCTORS TO ROOMS ---
    console.log("Starting Room Assignments...");
    const allDoctors = await Doctor.find({});
    const allRooms = await Room.find({});

    if (allRooms.length > 0) {
      // Clear old assignments if any
      await RoomAssignment.deleteMany({});
      
      for (let i = 0; i < allDoctors.length; i++) {
        const doctor = allDoctors[i];
        const assignedRoom = allRooms[i % allRooms.length]; // Distribute doctors across available rooms
        
        const assignment = new RoomAssignment({
          doctorId: doctor._id,
          roomId: assignedRoom._id,
          workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
          shift: 'Full',
          status: 'active'
        });
        
        await assignment.save();
        console.log(`✅ Assigned Doctor ${doctor._id} to Room ${assignedRoom.roomNumber}`);
      }
    } else {
      console.log("⚠️ No rooms found in DB to assign to doctors.");
    }

    console.log("✨ Enrichment & Room Assignment Completed Successfully!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error enriching doctors:", error);
    process.exit(1);
  }
};

updateDoctors();
