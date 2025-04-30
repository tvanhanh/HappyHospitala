import { Request, Response } from "express";
import Doctor, { IDoctor } from "../models/Doctor";
import Department,{IDepartment} from"../models/Departments";
import mongoose from 'mongoose';


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

// Lấy danh sách 
export const getDoctors = async (req: Request, res: Response) => {
  try {
    const doctors = await Doctor.find();
    const formattedDoctors = await Promise.all(
      doctors.map(async (doctor:IDoctor ) => {
        const department: IDepartment | null = await Department.findById(doctor.departmentName);
        return {
          _id: doctor._id.toString(),
          doctorName: doctor.doctorName || 'Không rõ tên',
          email: doctor.email || 'Chưa có',
          phone:doctor.phone || 'chưa có',
          address:doctor.address || 'chưa có',
          departmentId: doctor.departmentName.toString() || 'không rõ',
          departmentName: department?.departmentName || 'Không rõ',
          specialization: doctor.specialization || 'chưa có',
          avatar: doctor.avatar || ' chưa có',
        };
      })
    );
    res.status(200).json(formattedDoctors);
  } catch (error) {
    console.error("Lỗi khi lấy phòng ban", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

// Cập nhật 
export const updateDoctor = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { doctorName, email, phone,address, departmentName,specialization, avatar } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
       res.status(400).json({ message: 'ID không hợp lệ' });
       return;
    }

    const updated = await Doctor.findByIdAndUpdate(
      id,
      {doctorName, email, phone,address,departmentName, specialization,avatar   },
      { new: true }
    );

    if (!updated) {
       res.status(404).json({ message: "Không tìm thấy doctor" });
       return;
    }

    res.status(200).json({ message: "Cập nhật thành công", Doctor: updated });
  } catch (error) {
    console.error("Lỗi khi cập nhật phòng ban", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

// Xoá phòng ban
export const deleteDoctor = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
       res.status(400).json({ message: 'ID không hợp lệ' });
       return;
    }
    const deleted = await Doctor.findByIdAndDelete(id);

    if (!deleted) {
       res.status(404).json({ message: "Không tìm thấy phòng ban" });
       return;
    }

    res.status(200).json({ message: "Xoá thành công" });
  } catch (error) {
    console.error("Lỗi khi xoá phòng ban", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};
