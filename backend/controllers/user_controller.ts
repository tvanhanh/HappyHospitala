import { Request, Response, NextFunction } from "express";
import * as bcrypt from 'bcryptjs';
import User from "../models/User";
import Patient from "../models/Patient";
import mongoose from 'mongoose';
import { checkProfile } from "./utils/profileChecker";
// 🔥 UPDATE PROFILE
export const updateProfile = async (req: any, res: Response) => {
  try {
    const userId = req.user.id;
    const profileData = req.body.profile || {};

    // Update User model with basic fields
    const userUpdate: any = {};
    if (profileData.name) userUpdate.fullName = profileData.name;
    if (profileData.phone) userUpdate.phoneNumber = profileData.phone;
    if (profileData.address) userUpdate.address = profileData.address;
    if (profileData.gender) userUpdate.gender = profileData.gender;
    if (profileData.identityCard !== undefined) userUpdate.cccd = profileData.identityCard;
    if (profileData.avatar !== undefined) userUpdate.avatar = profileData.avatar;
    
    // Parse date format: handle both DD-MM-YYYY and YYYY-MM-DD
    if (profileData.dateOfBirth) {
      const dobStr = profileData.dateOfBirth.trim();
      let parsedDate: Date | null = null;
      
      // Try YYYY-MM-DD first
      if (/^\d{4}-\d{2}-\d{2}$/.test(dobStr)) {
        parsedDate = new Date(dobStr + 'T00:00:00Z');
      } 
      // Try DD-MM-YYYY format
      else if (/^\d{2}-\d{2}-\d{4}$/.test(dobStr)) {
        const [day, month, year] = dobStr.split('-');
        parsedDate = new Date(`${year}-${month}-${day}T00:00:00Z`);
      }
      
      if (parsedDate && !isNaN(parsedDate.getTime())) {
        userUpdate.dateOfBirth = parsedDate;
      } else {
        res.status(400).json({ message: "Invalid date format. Use YYYY-MM-DD or DD-MM-YYYY" });
        return;
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: userUpdate },
      { new: true }
    );

    if (!updatedUser) {
      res.status(404).json({ message: "Người dùng không tồn tại" });
      return;
    }

    // Update or create Patient record with patient-specific fields
    const patientUpdate: any = {};
    if (profileData.healthInsurance) patientUpdate.healthInsuranceCode = profileData.healthInsurance;
    if (profileData.bloodType) patientUpdate.bloodType = profileData.bloodType;
    if (profileData.allergies) patientUpdate.allergies = profileData.allergies;
    if (profileData.chronicDiseases) patientUpdate.chronicDiseases = profileData.chronicDiseases;
    if (profileData.emergencyContact) patientUpdate.emergencyContact = profileData.emergencyContact;

    // Only update Patient if there's relevant data
    if (Object.keys(patientUpdate).length > 0) {
      patientUpdate.userId = userId; // ensure userId for upsert
      await Patient.findOneAndUpdate(
        { userId },
        { $set: patientUpdate },
        { new: true, upsert: true }
      );
    }

    res.status(200).json({
      message: "Cập nhật thành công",
      user: updatedUser,
    });
  } catch (error) {
    console.error("updateProfile error:", error);
    res.status(500).json({ message: "Server error", error });
  }
};
export const getProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const user = await User.findById(req.user.id).select("-password");
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    // Fetch patient data if exists
    const patient = user.role === 'patient' ? await Patient.findOne({ userId: req.user.id }) : null;

    // Format profile data from User and Patient models
    const profile: any = {
      name: user.fullName || '',
      phone: user.phoneNumber || '',
      address: user.address || '',
      identityCard: user.cccd || '',
      gender: user.gender || '',
      avatar: user.avatar || '',
      dateOfBirth: (() => {
        if (!user.dateOfBirth) return '';
        try {
          const d = new Date(user.dateOfBirth);
          if (!isNaN(d.getTime())) {
            return d.toISOString().split('T')[0];
          }
        } catch (e) {}
        const str = String(user.dateOfBirth);
        return str.includes('T') ? str.split('T')[0] : str;
      })(),
      healthInsurance: patient?.healthInsuranceCode || '',
      walletAddress: '', // Not in current schema, add if needed
      bloodType: patient?.bloodType || '',
      allergies: patient?.allergies?.join(', ') || '',
      chronicDiseases: patient?.chronicDiseases?.join(', ') || '',
      emergencyContact: patient?.emergencyContact || { name: '', phone: '' }
    };

    // xác định loại check
    let type = "basic";
    if (user.role === "doctor") type = "medical";

    // check profile 1 lần thôi
    const profileStatus = checkProfile(user, type);

    res.status(200).json({
      success: true,
      profile,
      user: user.toObject(),
      profileStatus,
    });

  } catch (error) {
    console.error("getProfile error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const changePassWord = async(req: Request, res: Response)=>{
  try {
    const { email, newPassword } = req.body;
    //console.log("Dữ liệu nhận từ frontend:", req.body);
    
    if (!email || !newPassword) {
       res.status(400).json({ message: 'Thiếu email hoặc mật khẩu mới' });
       return;
    }
    const user = await User.findOne({ email });
    if (!user) {
       res.status(404).json({ message: 'Người dùng không tồn tại' });
       return;
    }
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();
    res.status(200).json({ message: 'Đổi mật khẩu thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error });
  }
}

export const getUserInfor = async (req: Request, res: Response) => {
  try {
    if (!req.user || !req.user.email) {
       res.status(401).json({ message: 'Người dùng chưa đăng nhập' });
       return;
    }

    const email = req.user.email;

    const medicalRecords = await User.find({ email }); // 👈 lọc theo email người dùng
    res.status(200).json(medicalRecords);
  } catch (error) {
    console.error("Lỗi khi lấy dữ liệu ", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

export const updateUserInfor = async (req: Request, res: Response) => {
  try {
    if (!req.user || !req.user.id) {
      res.status(401).json({ message: 'Người dùng chưa đăng nhập' });
      return;
    }
    const { id } = req.params;
    const { name, phone, address, gender, healthInsurance, avatar  } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {

       res.status(400).json({ message: 'ID không hợp lệ' });
       return;
    }

    const updated = await User.findByIdAndUpdate(
      id,
      { name, phone,address,gender,healthInsurance,avatar },
      { new: true }
    );

    if (!updated) {
       res.status(404).json({ message: "Không tìm thấy user" });
       return;
    }

    res.status(200).json({ message: "Cập nhật thành công", User: updated });
  } catch (error) {
    console.error("Lỗi khi cập nhật phòng ban", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

export const changePassword = async (req: Request, res: Response) => {
  try {
    const { email, oldPassword, newPassword, confirmNewPassword } = req.body;

    // Kiểm tra mật khẩu mới
    if (newPassword !== confirmNewPassword) {
      res.status(400).json({ message: "Mật khẩu mới không khớp." });
      return;
    }

    // Tìm người dùng
    const user = await User.findOne({ email });
    if (!user) {
      res.status(404).json({ message: "Không tìm thấy người dùng." });
      return;
    }

    // Kiểm tra mật khẩu cũ
    const isMatch = await bcrypt.compare(oldPassword, user.password || '');
    if (!isMatch) {
      res.status(400).json({ message: "Mật khẩu cũ không đúng." });
      return;
    }

    // Hash mật khẩu mới và cập nhật
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: "Đổi mật khẩu thành công." });
  } catch (error) {
    console.error("Lỗi đổi mật khẩu:", error);
    res.status(500).json({ message: "Lỗi server." });
  }}