import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import User from "../models/User";

// ================= TYPE =================
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

// ================= AUTH MIDDLEWARE =================
export const verifyToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ message: "Không có token" });
      return;
    }

    const token = authHeader.split(" ")[1];

    // ===== VERIFY TOKEN =====
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

    // 🔥 FIX QUAN TRỌNG: hỗ trợ cả id và _id
    const userId = decoded.id || decoded._id;

    if (!userId) {
      res.status(401).json({ message: "Token sai format" });
      return;
    }

    // ===== FIND USER =====
    const user = await User.findById(userId);

    if (!user) {
      res.status(401).json({ message: "Người dùng không tồn tại" });
      return;
    }

    // ===== SET REQUEST USER =====
   const u = user as any;

req.user = {
  id: u._id.toString(),
  email: u.email,
  role: u.role,
  status: u.status,
};

    next();
  } catch (error) {
    console.log("AUTH ERROR:", error);
    res.status(401).json({ message: "Token không hợp lệ" });
  }
};

// ================= ADMIN CHECK =================
export const isAdmin = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user || req.user.role !== "admin") {
    res.status(403).json({ message: "Chỉ admin mới được phép" });
    return;
  }
  next();
};