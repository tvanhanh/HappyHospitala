import { Request, Response } from "express";
import Doctor, { IDoctor } from "../models/Doctor";
import Department,{IDepartment} from"../models/Departments";
import mongoose from 'mongoose';
import User from "../models/User";

// Thêm phòng ban
export const addDoctors = async (req: Request, res: Response) => {
  try {
    const { doctorName, email, phone,address, departmentName, specialization,avatar } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);

    const newDoctors = new Doctor({
      doctorName,
      email,
      phone,
      address,
      departmentName,
      specialization,
      avatar,
      
    });

    await newDoctors.save();

    res.status(201).json({ message: "Thêm thành công", dotors: newDoctors });
  } catch (error) {
    console.error("Lỗi khi thêm bác sĩ", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

export const getDoctors = async (req: Request, res: Response) => {
  try {
    const doctors = await User.find({ role: "doctor" }).select("-password");

    res.status(200).json({
      message: "Get doctors success",
      data: doctors,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

export const updateDoctorProfile = async (req: Request, res: Response): Promise<void> => {
  try {
     console.log(req.body);

    const doctorId = req.params.id;
    const doctor = await User.findById(doctorId);
    if (!doctor) {
      res.status(404).json({ message: "Doctor not found" });
      return;
    }
     if (req.body.departmentId) {
      doctor.departmentId = req.body.departmentId;
    }
    doctor.profile = {
      ...(doctor.profile || {}),
      ...req.body,
    };
    await doctor.save();
    res.status(200).json({
      message: "Update success",
      doctor,
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

    const doctor = await User.findOne({
      _id: id,
      role: "doctor",
    });

    if (!doctor) {
      res.status(404).json({ message: "Không tìm thấy bác sĩ" });
      return;
    }

    res.status(200).json({
      message: "Lấy thông tin bác sĩ thành công",
      data: doctor,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Lỗi server" });
  }
};

export const getFeaturedDoctors = async (req: Request, res: Response) => {
  try {
    const doctors = await User.find({
  role: "doctor",
  isDeleted: false,
})
  .sort({ "profile.experience": -1 }) // 🔥 nhiều năm nhất lên đầu
  .limit(4)
  .lean();

    const result = doctors.map((d: any) => ({
      _id: d._id,
      name: d.name,
      avatar: d.profile?.avatar,
      specialty: d.profile?.specialty,
      experience: d.profile?.experience,
      price: d.profile?.price, // ⚠️ bạn đang đặt tên sai
    }));

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: "Lỗi server" });
  }
};
export const getDoctorsByDepartment = async (
  req: Request,
  res: Response
) => {
  try {
    const { departmentId } = req.params;
    console.log("Department =", req.params.departmentId);
    const doctors = await User.find({
      role: "doctor",
      departmentId: departmentId,
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