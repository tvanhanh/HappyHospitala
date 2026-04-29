import { Request, Response, NextFunction } from "express";
import * as bcrypt from 'bcryptjs';
import User from "../models/User";
import mongoose from 'mongoose';
import { checkProfile } from "./utils/profileChecker";
// 🔥 UPDATE PROFILE
export const updateProfile = async (req: any, res: Response) => {
  try {
    const userId = req.user.id;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          profile: req.body.profile, // ghi đè profile
        },
      },
      { new: true }
    );

    res.json({
      message: "Cập nhật thành công",
      user: updatedUser,
    });
  } catch (error) {
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
 // 👇 ĐẶT Ở ĐÂY
    console.log("REQ USER:", req.user);
    console.log("DB USER:", user);
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    // xác định loại check
    let type = "basic";
    if (user.role === "doctor") type = "medical";

    // check profile 1 lần thôi
    const profileStatus = checkProfile(user, type);

    res.json({
      ...user.toObject(),
      profileStatus,
    });

  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};

export const changePassWord = async(req: Request, res: Response)=>{
  try {
    const { email, newPassword } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);
    
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
    const isMatch = await bcrypt.compare(oldPassword, user.password);
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