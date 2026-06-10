import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import mongoose from 'mongoose';
import Doctor from '../models/Doctor';
import User from '../models/User';
import Appointment from '../models/Appointment';
import Specialty from '../models/Specialty';
import Room from '../models/Room';
import RoomAssignment from '../models/RoomAssignment';
import Patient from '../models/Patient';
import Staff from '../models/Staff';
import SpecialtyRoomDoctor from '../models/SpecialtyRoomDoctor';

export const getAdminStats = async (req: Request, res: Response) => {
  try {
    const totalDoctors = await Doctor.countDocuments();
    const totalPatients = await User.countDocuments({ role: 'patient' });
    const totalAppointments = await Appointment.countDocuments();
    const totalSpecialties = await Specialty.countDocuments();
    const totalRooms = await Room.countDocuments();

    res.status(200).json({
      totalDoctors,
      totalPatients,
      totalAppointments,
      totalSpecialties,
      totalRooms
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await User.find({}, '-password').sort({ createdAt: -1 });
    res.status(200).json(users);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getChartData = async (req: Request, res: Response) => {
  try {
    const specialties = await Specialty.find();
    const chartData = await Promise.all(
      specialties.map(async (spec) => {
    const count = await Doctor.countDocuments({ departmentId: spec._id });
        return { name: spec.name, count };
      })
    );

    res.status(200).json(chartData);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const createBaseAccount = async (req: Request, res: Response) => {
  try {
    const { name, email, password, role } = req.body;
    const fullName = name;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: "Vui lòng cung cấp đủ Name, Email, Password, và Role" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email đã tồn tại" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      fullName,
      email,
      password: hashedPassword,
      role,
      status: 'activity',
      isDeleted: false,
    });

    await newUser.save();
    
    let profile = null;

    try {
      switch (role) {
        case 'doctor':
          profile = new Doctor({ 
            userId: newUser._id, 
            profile_status: 'HIDDEN' 
          });
          await profile.save();
          break;
        case 'patient':
          profile = new Patient({ userId: newUser._id });
          await profile.save();
          break;
        case 'receptionist':
        case 'cashier':
        case 'pharmacy':
          profile = new Staff({ 
            userId: newUser._id, 
            position: role 
          });
          await profile.save();
          break;
        default:
          break;
      }
    } catch (profileError: any) {
      // Rollback Strategy: delete the newUser to avoid orphaned base accounts
      await User.findByIdAndDelete(newUser._id);
      return res.status(500).json({ 
        message: `Lỗi tạo Profile. Đã hoàn tác tài khoản cơ sở. Error: ${profileError.message}` 
      });
    }

    res.status(201).json({ 
      message: "Tạo tài khoản thành công", 
      user: newUser,
      profile 
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const toggleUserStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: "Không tìm thấy user" });
    }
    
    // Default to 'activity' if status is missing in DB
    const currentStatus = user.status || 'activity';
    
    // Toggle status
    user.status = currentStatus === 'activity' ? 'inactive' : 'activity';
    await user.save();
    
    res.status(200).json({ message: `Đã ${user.status === 'activity' ? 'mở khóa' : 'khóa'} tài khoản thành công`, user });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getPendingDoctors = async (req: Request, res: Response) => {
  try {
    // 1. Fetch Doctor profiles that are PENDING_APPROVAL or HIDDEN
    const pendingProfiles = await Doctor.find({
      profile_status: { $in: ['PENDING_APPROVAL', 'HIDDEN'] }
    }).populate('userId', '-password').populate('departmentId');

    // 2. Format response to include user info + profile info
    const formattedPendingDoctors = pendingProfiles.map((doc: any) => {
      const user = doc.userId;
      if (!user) return null;
      const department = doc.departmentId;
      const specialtyName = doc.specialty || department?.name || department?.departmentName || '';
      return {
        _id: user._id,
        email: user.email,
        name: user.fullName,
        phone: user.phoneNumber,
        status: user.status,
        role: user.role,
        avatar: user.avatar || '',
        profile_status: doc.profile_status,
        specialty: specialtyName,
        experience_years: doc.experience_years,
        bio: doc.bio,
        education: doc.education,
        certifications_urls: doc.certifications_urls,
        consultationFee: doc.consultationFee
      };
    }).filter(d => d !== null);
    
    res.status(200).json(formattedPendingDoctors);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getRejectedDoctors = async (req: Request, res: Response) => {
  try {
    const rejectedProfiles = await Doctor.find({
      profile_status: 'REJECTED'
    }).populate('userId', '-password').populate('departmentId');

    const formattedRejectedDoctors = rejectedProfiles.map((doc: any) => {
      const user = doc.userId;
      if (!user) return null;
      const department = doc.departmentId;
      const specialtyName = doc.specialty || department?.name || department?.departmentName || '';
      return {
        _id: user._id,
        email: user.email,
        name: user.fullName,
        phone: user.phoneNumber,
        status: user.status,
        role: user.role,
        avatar: user.avatar || '',
        profile_status: doc.profile_status,
        specialty: specialtyName,
        experience_years: doc.experience_years,
        bio: doc.bio,
        education: doc.education,
        certifications_urls: doc.certifications_urls,
        consultationFee: doc.consultationFee,
        rejection_reason: doc.rejection_reason
      };
    }).filter(d => d !== null);
    
    res.status(200).json(formattedRejectedDoctors);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const approveDoctor = async (req: Request, res: Response) => {
  try {
    const { userId, departmentId, roomId, specialty } = req.body;
    
    const user = await User.findById(userId);
    if (!user || user.role !== 'doctor') {
      return res.status(404).json({ message: "Không tìm thấy User hoặc User không phải Bác sĩ" });
    }

    const specialtyDoc = departmentId ? await Specialty.findById(departmentId) : null;
    const specialtyName = specialty || specialtyDoc?.name || undefined;

    let doctor = await Doctor.findOne({ userId: user._id });
    if (doctor) {
      if (doctor.profile_status === 'ACTIVE') {
        return res.status(400).json({ message: "Bác sĩ này đã được duyệt trước đó!" });
      }
      doctor.departmentId = departmentId;
      if (roomId) doctor.roomId = roomId;
      if (specialtyName) doctor.specialty = specialtyName;
      doctor.profile_status = 'ACTIVE';
      await doctor.save();
    } else {
      doctor = new Doctor({
        userId: user._id,
        departmentId: departmentId,
        roomId: roomId || undefined,
        specialty: specialtyName,
        profile_status: 'ACTIVE'
      });
      await doctor.save();
    }

    // Update base User status to active
    user.status = 'activity';
    await user.save();

    if (roomId) {
      const assignment = new RoomAssignment({
        doctorId: doctor._id,
        roomId: roomId,
        status: 'active'
      });
      await assignment.save();

      // Upsert mapping in SpecialtyRoomDoctor if departmentId/specialtyId is also assigned
      if (departmentId) {
        await SpecialtyRoomDoctor.findOneAndUpdate(
          { specialtyId: departmentId, roomId: roomId, doctorId: doctor._id },
          { specialtyId: departmentId, roomId: roomId, doctorId: doctor._id },
          { upsert: true, new: true }
        );
      }
    }

    res.status(200).json({ 
      message: "Phê duyệt Bác sĩ thành công", 
      doctor 
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const rejectDoctor = async (req: Request, res: Response) => {
  try {
    const { userId, reason } = req.body;
    
    const user = await User.findById(userId);
    if (!user || user.role !== 'doctor') {
      return res.status(404).json({ message: "Không tìm thấy User hoặc User không phải Bác sĩ" });
    }

    let doctor = await Doctor.findOne({ userId: user._id });
    if (doctor) {
      doctor.profile_status = 'REJECTED';
      // Mute reason saving for now if schema doesn't support it, but we set status
      await doctor.save();
    }

    res.status(200).json({ 
      message: "Đã từ chối hồ sơ bác sĩ", 
      doctor 
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getActiveDoctors = async (req: Request, res: Response) => {
  try {
    const activeDoctors = await Doctor.find().populate('departmentId', 'name').populate('userId', 'fullName email phone avatar').lean();
    
    const assignments = await RoomAssignment.find({ status: 'active' }).populate('roomId', 'roomNumber');
    
    const mappedDoctors = activeDoctors.map((doc: any) => {
      const assignment = assignments.find(a => a.doctorId.toString() === doc._id.toString());
      return {
        ...doc,
        roomId: assignment ? assignment.roomId : null
      };
    });

    res.status(200).json(mappedDoctors);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateDoctorFee = async (req: Request, res: Response) => {
  try {
    const { id } = req.params; // This is now User ID
    const { consultationFee } = req.body;

    const doctor = await Doctor.findOneAndUpdate(
      { userId: id },
      { consultationFee },
      { new: true }
    ).populate('departmentId', 'name').populate('userId', 'fullName email').lean();

    if (!doctor) {
      return res.status(404).json({ message: "Không tìm thấy bác sĩ" });
    }

    const assignment = await RoomAssignment.findOne({ doctorId: doctor._id, status: 'active' }).populate('roomId', 'roomNumber');
    const mappedDoctor = {
      ...doctor,
      roomId: assignment ? assignment.roomId : null
    };

    res.status(200).json({ message: "Cập nhật giá khám thành công", doctor: mappedDoctor });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
