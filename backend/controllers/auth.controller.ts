import { Request, Response, NextFunction } from "express";
import User from "../models/User";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password, confirmPassword, role } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);


    if (password !== confirmPassword) {
       res.status(400).json({ message: "Mật khẩu không khớpkhớp." });
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
      role: role || "admin",
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
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: "7d" }
    );

    res.status(200).json({
      token,
      user: {
        id: user._id,
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