import { Request, Response } from "express";
import Doctor, { IDoctor } from "../models/Doctor";
import Department,{IDepartment} from"../models/Departments";
import mongoose from 'mongoose';
import User from "../models/User";
import RoomAssignment from "../models/RoomAssignment";
import SpecialtyRoomDoctor from "../models/SpecialtyRoomDoctor";

// Thêm phòng ban
export const addDoctors = async (req: Request, res: Response) => {
  try {
    const { doctorName, email, phone, address, departmentName, specialization, avatar, specialtyId, roomId } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);

    const newUser = new User({
      fullName: doctorName,
      email,
      phoneNumber: phone,
      address,
      avatar,
      role: 'doctor',
      status: 'activity'
    });
    await newUser.save();

    const newDoctors = new Doctor({
      userId: newUser._id,
      bio: specialization,
      specialtyId: specialtyId || undefined,
      roomId: roomId || undefined,
      profile_status: 'ACTIVE'
    });

    await newDoctors.save();

    if (roomId) {
      const assignment = new RoomAssignment({
        doctorId: newDoctors._id,
        roomId: roomId,
        status: 'active'
      });
      await assignment.save();

      if (specialtyId) {
        await SpecialtyRoomDoctor.findOneAndUpdate(
          { specialtyId: specialtyId, roomId: roomId, doctorId: newDoctors._id },
          { specialtyId: specialtyId, roomId: roomId, doctorId: newDoctors._id },
          { upsert: true, new: true }
        );
      }
    }

    res.status(201).json({ message: "Thêm thành công", dotors: newDoctors });
  } catch (error) {
    console.error("Lỗi khi thêm bác sĩ", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};
export const getDoctors = async (req: Request, res: Response) => {
  try {
    // 1. Phải lấy từ bảng Doctor (Hồ sơ) chứ KHÔNG PHẢI bảng User
    const doctors = await Doctor.find({ /* điều kiện của bạn */ })
      .populate('userId', 'fullName email avatar') // Gộp thông tin User vào
      .populate('specialtyId', 'name');

    // 2. Chế biến lại dữ liệu trước khi gửi cho Flutter
    const formattedDoctors = doctors.map(doc => {
      // Ép kiểu an toàn để tránh lỗi TypeScript
      const user = doc.userId as any; 
      const spec = doc.specialtyId as any;

      return {
        _id: doc._id, // ĐÂY RỒI! ĐÂY MỚI LÀ DOCTOR ID CHUẨN ĐỂ FLUTTER GỬI ĐI!
        userId: user ? user._id : null, // Giữ lại userId nếu app cần dùng việc khác
        name: user ? user.fullName : 'Vô danh',
        email: user ? user.email : '',
        avatar: user ? user.avatar : '',
        specialty: spec ? spec.name : '',
        specialtyId_id: spec ? spec._id : null,
        experience_years: doc.experience_years,
        consultationFee: doc.consultationFee,
        bio: doc.bio
      };
    });

    res.status(200).json({
      message: "Get doctors success",
      data: formattedDoctors, // Trả mảng đã format chuẩn cho Flutter
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
export const updateDoctorProfile = async (req: Request, res: Response): Promise<void> => {
  try {

    console.log(req.body);

    const doctorId = req.params.id;
    const user = await User.findById(doctorId);
    if (!user) {
      res.status(404).json({ message: "Doctor not found" });
      return;
    }

    if (req.body.phoneNumber) user.phoneNumber = req.body.phoneNumber;
    if (req.body.address) user.address = req.body.address;
    if (req.body.avatar) user.avatar = req.body.avatar;
    if (req.body.fullName) user.fullName = req.body.fullName;
    await user.save();

    let doctorProfile = await Doctor.findOne({ userId: doctorId });
    if (!doctorProfile) {
      doctorProfile = new Doctor({ userId: doctorId, profile_status: 'HIDDEN' });
    }
    
    if (req.body.specialtyId) {
      doctorProfile.specialtyId = req.body.specialtyId;
    }
    if (req.body.bio) doctorProfile.bio = req.body.bio;
    await doctorProfile.save();

    res.status(200).json({
      message: "Update success",
      doctor: user,
    });
    return;

  } catch (error) {
    console.error("UPDATE ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: String(error),
    });
    return;
  }
}

export const getDoctorById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: "ID không hợp lệ" });
      return;
    }

    // Try finding by doctor profile ID first, populate User, Department
    let doctorProfile = await Doctor.findById(id)
      .populate("userId", "-password")
      .populate("specialtyId");

    // If not found by Doctor ID, try finding by User ID (userId)
    if (!doctorProfile) {
      doctorProfile = await Doctor.findOne({ userId: id })
        .populate("userId", "-password")
        .populate("specialtyId");
    }

    if (!doctorProfile) {
      res.status(404).json({ message: "Không tìm thấy thông tin bác sĩ" });
      return;
    }

    let roomInfo = null;
    const assignment = await RoomAssignment.findOne({ doctorId: doctorProfile._id, status: 'active' }).populate('roomId');
    if (assignment && assignment.roomId) {
      roomInfo = assignment.roomId;
    }

    const result = doctorProfile.toObject();
    (result as any).roomId = roomInfo;

    res.status(200).json({
      message: "Lấy thông tin bác sĩ thành công",
      data: result,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Lỗi server" });
  }
};
export const getDoctorsByDepartment = async (
  req: Request,
  res: Response
) => {
  try {
    const { specialtyId } = req.params;
    console.log("Department =", req.params.specialtyId);
    const doctors = await User.find({
      role: "doctor",
      specialtyId: specialtyId,
      isDeleted: false,
    }).select(
      "_id name profile.avatar profile.specialty"
    );

    res.status(200).json(doctors);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
    });
  }
};

export const getFeaturedDoctors = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const doctors = await Doctor.find()
      .limit(6)
      .populate('specialtyId', 'name')
      .populate('userId', 'fullName email phoneNumber avatar')
      .lean();

    const result = doctors.map((d: any) => {
      const user = d.userId as any;
      return {
        _id: d._id,
        name: user?.fullName,
        email: user?.email,
        phone: user?.phoneNumber,
        avatar: user?.avatar,
        specialtyId: d.specialtyId ? d.specialtyId._id : null,
        specialty: d.specialtyId ? d.specialtyId.name : null,
        price: d.consultationFee,
      };
    });

    res.status(200).json({
      message: "Lấy danh sách bác sĩ nổi bật thành công",
      data: result,
    });
    return;
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Lỗi server" });
    return;
  }
};