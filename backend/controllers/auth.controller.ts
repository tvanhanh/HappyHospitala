import { Request, Response, NextFunction } from "express";
import * as bcrypt from 'bcryptjs';
import User from "../models/User";
import mongoose from 'mongoose';
import jwt from "jsonwebtoken";
import Otp from "../models/Otp";
import { sendEmailOTP, sendSmsOTP } from "../utils/otpSender";
import { OAuth2Client } from 'google-auth-library';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID || "YOUR_GOOGLE_CLIENT_ID");

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password, confirmPassword, role, status } = req.body;
    const fullName = name;
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
    // Kiểm tra OTP trước
    const { otp } = req.body;
    if (!otp) {
       res.status(400).json({ message: "Vui lòng nhập mã OTP." });
       return;
    }

    const otpRecord = await Otp.findOne({ email, otp });
    if (!otpRecord) {
       res.status(400).json({ message: "OTP không hợp lệ hoặc đã hết hạn." });
       return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Xóa OTP sau khi dùng
    await Otp.deleteOne({ _id: otpRecord._id });

    const isPhone = /^\d+$/.test(email);
    // Tạo user mới (không lưu rePassword)
    const newUser = new User({
      fullName,
      email,
      phoneNumber: isPhone ? email : undefined,
      password:hashedPassword,
      role: role || "patient",
      status: status || "activity",
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
    const fullName = name;
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
      fullName,
      email,
      password:hashedPassword,
      role,
      status: status || "activity",
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

    if (user.status === 'inactive') {
      res.status(403).json({ message: "Tài khoản của bạn đã bị khóa do có hành vi đáng ngờ. Vui lòng liên hệ Admin." });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.password || '');

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
        name: user.fullName,
        email: user.email,
        role: user.role,
        avatar: user.avatar || '',
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

export const sendOtpRegister = async (req: Request, res: Response) => {
  try {
    const { emailOrPhone } = req.body;
    if (!emailOrPhone) {
      res.status(400).json({ message: "Vui lòng nhập Email hoặc Số điện thoại." });
      return;
    }

    // Kiểm tra xem đã tồn tại chưa (trong DB đang dùng trường email)
    const existingUser = await User.findOne({ email: emailOrPhone });
    if (existingUser) {
      res.status(400).json({ message: "Tài khoản (Email/SĐT) đã tồn tại." });
      return;
    }

    // Xóa các OTP cũ của email/phone này
    await Otp.deleteMany({ email: emailOrPhone });

    // Tạo OTP mới 6 số
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    const newOtp = new Otp({
      email: emailOrPhone,
      otp: otpCode,
    });
    await newOtp.save();

    let isSent = false;

    // Kiểm tra định dạng: Nếu chứa @ thì gửi Email, nếu không thì gửi SMS
    if (emailOrPhone.includes('@')) {
      isSent = await sendEmailOTP(emailOrPhone, otpCode);
    } else {
      isSent = await sendSmsOTP(emailOrPhone, otpCode);
    }

    // Nếu gửi thất bại (do thiếu biến môi trường, hoặc lỗi dịch vụ thứ 3), in ra Console để đi Demo
    if (!isSent) {
      console.log(`\n==============================================`);
      console.log(`🔑 MÃ OTP CHO [${emailOrPhone}] LÀ: ${otpCode}`);
      console.log(`(Lưu ý: In ra màn hình do chưa cấu hình SMTP/Twilio trong .env)`);
      console.log(`==============================================\n`);
    }

    res.status(200).json({ message: "Mã OTP đã được gửi.", otp: otpCode });
  } catch (error) {
    console.error("Lỗi gửi OTP đăng ký:", error);
    res.status(500).json({ message: "Lỗi server khi gửi OTP." });
  }
};

export const googleLogin = async (req: Request, res: Response) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      res.status(400).json({ message: "Thiếu idToken từ Google." });
      return;
    }

    // Xác minh idToken
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID || "YOUR_GOOGLE_CLIENT_ID", 
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email) {
      res.status(400).json({ message: "Google Token không hợp lệ." });
      return;
    }

    const { email, name, picture } = payload;

    // Tìm user trong DB
    let user = await User.findOne({ email });

    // Nếu user chưa tồn tại, tự động tạo mới
    if (!user) {
      const generatedPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
      const hashedPassword = await bcrypt.hash(generatedPassword, 10);
      user = new User({
        fullName: name,
        email,
        password: hashedPassword,
        role: "patient", // Mặc định role là patient
        status: "activity",
      });
      await user.save();
    }

    // Nếu user bị khóa
    if (user.status !== "activity") {
      res.status(403).json({ message: "Tài khoản của bạn đã bị khóa." });
      return;
    }

    // Tạo JWT token của hệ thống
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET || "smartclinic_secret",
      { expiresIn: "1d" }
    );

    res.status(200).json({
      message: "Đăng nhập Google thành công!",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        avatar: picture,
      },
    });
  } catch (error) {
    console.error("Lỗi đăng nhập Google:", error);
    res.status(500).json({ message: "Lỗi server xác minh Google." });
  }
};

export const sendOtpForgot = async (req: Request, res: Response) => {
  try {
    const { emailOrPhone } = req.body;
    if (!emailOrPhone) {
      res.status(400).json({ message: "Vui lòng nhập Email hoặc Số điện thoại." });
      return;
    }

    // Kiểm tra xem user có tồn tại không (trong DB đang dùng trường email)
    const user = await User.findOne({ email: emailOrPhone });
    if (!user) {
      res.status(404).json({ message: "Tài khoản không tồn tại trên hệ thống." });
      return;
    }

    // Xóa các OTP cũ của email/phone này
    await Otp.deleteMany({ email: emailOrPhone });

    // Tạo OTP mới 6 số
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    const newOtp = new Otp({
      email: emailOrPhone,
      otp: otpCode,
    });
    await newOtp.save();

    let isSent = false;

    // Kiểm tra định dạng: Nếu chứa @ thì gửi Email, nếu không thì gửi SMS
    if (emailOrPhone.includes('@')) {
      isSent = await sendEmailOTP(emailOrPhone, otpCode, 'forgot');
    } else {
      isSent = await sendSmsOTP(emailOrPhone, otpCode, 'forgot');
    }

    // Nếu gửi thất bại, in ra Console để đi Demo
    if (!isSent) {
      console.log(`\n==============================================`);
      console.log(`🔑 MÃ OTP QUÊN MẬT KHẨU CHO [${emailOrPhone}] LÀ: ${otpCode}`);
      console.log(`(Lưu ý: In ra màn hình do chưa cấu hình SMTP/Twilio trong .env)`);
      console.log(`==============================================\n`);
    }

    res.status(200).json({ message: "Mã OTP đã được gửi.", otp: otpCode });
  } catch (error) {
    console.error("Lỗi gửi OTP quên mật khẩu:", error);
    res.status(500).json({ message: "Lỗi server khi gửi OTP." });
  }
};

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { emailOrPhone, otp, newPassword, confirmPassword } = req.body;

    if (!emailOrPhone || !otp || !newPassword || !confirmPassword) {
      res.status(400).json({ message: "Vui lòng điền đầy đủ thông tin." });
      return;
    }

    if (newPassword !== confirmPassword) {
      res.status(400).json({ message: "Mật khẩu xác nhận không khớp." });
      return;
    }

    // Xác thực OTP
    const otpRecord = await Otp.findOne({ email: emailOrPhone, otp });
    if (!otpRecord) {
      res.status(400).json({ message: "Mã OTP không hợp lệ hoặc đã hết hạn." });
      return;
    }

    // Tìm user
    const user = await User.findOne({ email: emailOrPhone });
    if (!user) {
      res.status(404).json({ message: "Người dùng không tồn tại." });
      return;
    }

    // Cập nhật mật khẩu mới
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    // Xóa OTP sau khi dùng
    await Otp.deleteOne({ _id: otpRecord._id });

    res.status(200).json({ message: "Đặt lại mật khẩu thành công!" });
  } catch (error) {
    console.error("Lỗi đặt lại mật khẩu:", error);
    res.status(500).json({ message: "Lỗi server khi đặt lại mật khẩu." });
  }
};

