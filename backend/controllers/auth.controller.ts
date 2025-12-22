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
      personalData: {}
    });

    await newUser.save();

    res.status(201).json({ message: "Tạo tài khoản thành công!" });
  } catch (error) {
    console.error("Lỗi đăng ký:", error);
    res.status(500).json({ message: "Lỗi server." });
  }
};
export const createUserByAdmin = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { name, email, password, rePassword, role } = req.body;

    if (password !== rePassword) {
       res.status(400).json({ message: 'Mật khẩu không khớp' });
       return;
    }

    if (!['doctor', 'staff'].includes(role)) {
       res.status(400).json({ message: 'Role không hợp lệ (chỉ cho phép doctor/staff)' });
       return;
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
       res.status(400).json({ message: 'Email đã tồn tại' });
       return;
    }

    const newUser = new User({ name, email, password, role });
    await newUser.save();

     res.status(201).json({ message: `Tạo tài khoản ${role} thành công!` });
     return;
  } catch (err) {
    console.error('Lỗi khi tạo tài khoản:', err);
     res.status(500).json({ message: 'Lỗi server' });
     return;
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
    console.log("Mật khẩu trong MongoDB:", user.password);
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
       res.status(400).json({ message: "Mật khẩu không đúng" });
       return;
    }
    // 3. Tạo JWT token
    const token = jwt.sign(
      { _id: user._id.toString(),
        role: user.role,
        email: user.email },
      process.env.JWT_SECRET!,
      { expiresIn: "7d" }
    );

    res.status(200).json({
      token,
      user: {
        _id: user._id,
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

export const logout = (req: Request, res: Response) => {
  // Xóa token phía client (nếu lưu ở cookie)
  res.clearCookie('token'); // nếu có lưu token ở cookie
  res.status(200).json({ message: "Đăng xuất thành công" });
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