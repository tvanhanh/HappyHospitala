import { Request, Response } from "express";
import { PremiumPackage, UserSubscription } from "../models/PremiumPackage";

// ── PACKAGE CRUD ───────────────────────────────────────────────────────────
export const getAllPackages = async (req: Request, res: Response): Promise<any> => {
  try {
    const packages = await PremiumPackage.find().sort({ sortOrder: 1 });
    res.json({ success: true, data: packages });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

export const createPackage = async (req: Request, res: Response): Promise<any> => {
  try {
    const pkg = await PremiumPackage.create(req.body);
    res.status(201).json({ success: true, data: pkg, message: "Tạo gói thành công" });
  } catch (err: any) {
    if (err.code === 11000) return res.status(400).json({ success: false, message: "Slug đã tồn tại" });
    res.status(500).json({ success: false, message: "Lỗi tạo gói" });
  }
};

export const updatePackage = async (req: Request, res: Response): Promise<any> => {
  try {
    const pkg = await PremiumPackage.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!pkg) return res.status(404).json({ success: false, message: "Không tìm thấy" });
    res.json({ success: true, data: pkg });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi cập nhật" });
  }
};

export const deletePackage = async (req: Request, res: Response): Promise<any> => {
  try {
    await PremiumPackage.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Đã xóa gói" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi xóa" });
  }
};

// ── SUBSCRIPTIONS ─────────────────────────────────────────────────────────
export const getAllSubscriptions = async (req: Request, res: Response): Promise<any> => {
  try {
    const subs = await UserSubscription.find()
      .populate("userId", "name email profile")
      .populate("packageId", "name price slug color")
      .sort({ createdAt: -1 });
    res.json({ success: true, data: subs });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi lấy danh sách" });
  }
};

export const subscribe = async (req: any, res: Response): Promise<any> => {
  try {
    const { packageId, paymentMethod, userId: bodyUserId } = req.body;
    const userId = bodyUserId || req.user?.id;

    const pkg = await PremiumPackage.findById(packageId);
    if (!pkg) return res.status(404).json({ success: false, message: "Không tìm thấy gói" });

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + pkg.durationDays);

    // Cancel old active subscription if exists
    await UserSubscription.updateMany(
      { userId, status: "active" },
      { status: "cancelled" }
    );

    const sub = await UserSubscription.create({
      userId,
      packageId,
      startDate,
      endDate,
      paymentMethod: paymentMethod || "cash",
      amountPaid: pkg.price,
      status: "active",
    });

    res.status(201).json({ success: true, data: sub, message: `Đăng ký gói ${pkg.name} thành công` });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi đăng ký gói" });
  }
};

export const getUserSubscription = async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;
    const now = new Date();
    const sub = await UserSubscription.findOne({
      userId,
      status: "active",
      endDate: { $gte: now },
    }).populate("packageId");
    res.json({ success: true, data: sub });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi lấy thông tin" });
  }
};
