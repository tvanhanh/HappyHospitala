import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import User from "../models/User";

// Khai báo type cho Request (nếu dùng Cách 1)
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role?: string;
        status?: string;
      };
    }
  }
}

export const verifyToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    res.status(401).json({ message: "Không có token" });
    return;
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      _id: string;
      email: string;
    };

    // Tìm người dùng trong cơ sở dữ liệu để lấy role
    const user = await User.findById(decoded._id);
    if (!user) {
      res.status(401).json({ message: "Người dùng không tồn tại" });
      return;
    }

    // Gán req.user với thông tin bao gồm role
    req.user = {
      id: decoded._id,
      email: decoded.email,
      role: user.role, // Giả sử User model có trường role
      status: user.status,
    };

    next();
  } catch (error) {
    res.status(401).json({ message: "Token không hợp lệ" });
    return;
  }
};

export const isAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user || req.user.role !== "admin") {
    res.status(403).json({ message: "Chỉ admin mới được phép" });
    return;
  }
  next();
};