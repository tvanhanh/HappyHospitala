import { Request, Response, NextFunction } from "express";
import * as bcrypt from 'bcryptjs';
import User from "../models/User";
import mongoose from 'mongoose';
import jwt from "jsonwebtoken";
import Otp from "../models/Otp";

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password, confirmPassword, role, status } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);


    if (password !== confirmPassword) {
       res.status(400).json({ message: "Mật khẩu không khớp." });
       return;
    }
    // Kiểm tra email đã tồn tại chưa
    const existingUser = await User.findOne({ email });
    if (existingUser) {
       res.status(400).json({ message: "Email đã tồn tại." });
       return;
    }
    const hashedPassword = await bcrypt.hash(password, 10);

    // Tạo user mới (không lưu rePassword)
    const newUser = new User({
      name,
      email,
      password:hashedPassword,
      role: role || "patient",
      status: status || "activity",
      profile: {}
    });

    await newUser.save();

    res.status(201).json({ message: "Tạo tài khoản thành công!" });
  } catch (error) {
    console.error("Lỗi đăng ký:", error);
    res.status(500).json({ message: "Lỗi server." });
  }
};

export const registerByAdmin = async (req: Request, res: Response) => {
  try {
    const { name, email, password, confirmPassword, role, status } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);


    if (password !== confirmPassword) {
       res.status(400).json({ message: "Mật khẩu không khớp." });
       return;
    }
    // Kiểm tra email đã tồn tại chưa
    const existingUser = await User.findOne({ email });
    if (existingUser) {
       res.status(400).json({ message: "Email đã tồn tại." });
       return;
    }
    const hashedPassword = await bcrypt.hash(password, 10);

    // Tạo user mới (không lưu rePassword)
    const newUser = new User({
      name,
      email,
      password:hashedPassword,
      role,
      status: status || "activity",
      profile: {}
    });

    await newUser.save();

    res.status(201).json({ message: "Tạo tài khoản thành công!" });
  } catch (error) {
    console.error("Lỗi đăng ký:", error);
    res.status(500).json({ message: "Lỗi server." });
  }
};


export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    console.log("Dữ liệu nhận từ frontend:", req.body);

    const user = await User.findOne({ email });

    if (!user) {
      res.status(400).json({ message: "Email không tồn tại" });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      res.status(400).json({ message: "Mật khẩu không đúng" });
      return;
    }

    const token = jwt.sign(
      {
        _id: (user._id as mongoose.Types.ObjectId).toString(),
        role: user.role,
        email: user.email,
      },
      process.env.JWT_SECRET!,
      { expiresIn: "7d" }
    );

    res.status(200).json({
      token,
      user: {
        _id: (user._id as mongoose.Types.ObjectId).toString(),
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });

  } catch (error) {
    console.error("Lỗi đăng nhập:", error);
    res.status(500).json({ message: "Lỗi server" });
  }
};
  
export const verifyOtp = async (req: Request, res: Response) => {
  const { email, otp } = req.body;

  try {
    const record = await Otp.findOne({ email, otp });

    if (!record) {
       res.status(400).json({ message: "OTP không hợp lệ hoặc đã hết hạn." });
       return;
    }

    // Nếu đúng, xóa OTP để không dùng lại
    await Otp.deleteOne({ _id: record._id });

    // Có thể gửi token hoặc redirect qua FE để đổi mật khẩu
    res.status(200).json({ message: "OTP hợp lệ. Cho phép đổi mật khẩu." });
  } catch (err) {
    console.error("Lỗi xác minh OTP:", err);
    res.status(500).json({ message: "Lỗi server khi xác minh OTP." });
  }
};

export const logout = (req: Request, res: Response) => {
  // Xóa token phía client (nếu lưu ở cookie)
  res.clearCookie('token'); // nếu có lưu token ở cookie
  res.status(200).json({ message: "Đăng xuất thành công" });
};

