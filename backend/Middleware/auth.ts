import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import User from "../models/User";

export const verifyToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    res.status(401).json({ message: "Không có token" });
    return;  // Khi không có token, trả về lỗi và dừng lại
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { userId: string };
    const user = await User.findById(decoded.userId);
    if (!user) {
      res.status(401).json({ message: "Người dùng không tồn tại" });
      return;  // Nếu người dùng không tồn tại, trả về lỗi và dừng lại
    }

    (req as any).user = user;
    next(); 
  } catch (error) {
    res.status(401).json({ message: "Token không hợp lệ" });
  }
};

export const isAdmin = (req: Request, res: Response, next: NextFunction): void => {
  const user = (req as any).user;
  if (user.role !== "admin") {
     res.status(403).json({ message: "Chỉ admin mới được phép" });
     return;
  }
  next();  // Nếu là admin, tiếp tục với middleware tiếp theo
};
