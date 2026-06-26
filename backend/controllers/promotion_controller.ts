import { Request, Response } from "express";

import Appointment from "../models/Appointment";
import Promotion from "../models/Promotion";

// ── GET ALL ─────────────────────────────────────────────────────────────────
export const getAllPromotions = async (req: Request, res: Response): Promise<any> => {
  try {
    const promotions = await Promotion.find().sort({ createdAt: -1 });
    res.json({ success: true, data: promotions });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server", error: err });
  }
};

// ── GET ACTIVE ─────────────────────────────────────────────────────────────
export const getActivePromotions = async (req: Request, res: Response): Promise<any> => {
  try {
    const now = new Date();
    const promotions = await Promotion.find({
      isActive: true,
      validFrom: { $lte: now },
      validTo: { $gte: now },
    });
    res.json({ success: true, data: promotions });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

// ── CREATE ─────────────────────────────────────────────────────────────────
export const createPromotion = async (req: any, res: Response): Promise<any> => {
  try {
    const data = req.body;
    // Validate dates
    if (new Date(data.validFrom) >= new Date(data.validTo)) {
      return res.status(400).json({ success: false, message: "Ngày bắt đầu phải trước ngày kết thúc" });
    }
    const promotion = await Promotion.create({
      ...data,
      createdBy: req.user?.id,
    });
    res.status(201).json({ success: true, data: promotion, message: "Tạo khuyến mãi thành công" });
  } catch (err: any) {
    if (err.code === 11000) {
      return res.status(400).json({ success: false, message: "Mã khuyến mãi đã tồn tại" });
    }
    res.status(500).json({ success: false, message: "Lỗi tạo khuyến mãi", error: err });
  }
};

// ── UPDATE ─────────────────────────────────────────────────────────────────
export const updatePromotion = async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const updated = await Promotion.findByIdAndUpdate(id, req.body, { new: true, runValidators: true });
    if (!updated) return res.status(404).json({ success: false, message: "Không tìm thấy khuyến mãi" });
    res.json({ success: true, data: updated, message: "Cập nhật thành công" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi cập nhật" });
  }
};

// ── DELETE ─────────────────────────────────────────────────────────────────
export const deletePromotion = async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    await Promotion.findByIdAndDelete(id);
    res.json({ success: true, message: "Đã xóa khuyến mãi" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi xóa" });
  }
};

// ── VALIDATE CODE ──────────────────────────────────────────────────────────
/**
 * Kiểm tra mã khuyến mãi hợp lệ và tính số tiền giảm.
 * Body: { code, amount, patientId?, isInsurance?, isPremium? }
 */
export const validatePromoCode = async (req: Request, res: Response): Promise<any> => {
  try {
    const { code, amount = 0 } = req.body;
    if (!code) return res.status(400).json({ success: false, message: "Thiếu mã khuyến mãi" });

    const now = new Date();
    const promo = await Promotion.findOne({
      code: code.trim().toUpperCase(),
      isActive: true,
      validFrom: { $lte: now },
      validTo: { $gte: now },
    });

    if (!promo) {
      return res.json({ success: false, valid: false, message: "Mã không hợp lệ hoặc đã hết hạn" });
    }

    // Check usage limit
    if (promo.maxUsage && promo.usedCount >= promo.maxUsage) {
      return res.json({ success: false, valid: false, message: "Mã đã đạt giới hạn sử dụng" });
    }

    // Check min amount
    if (promo.minAmount && amount < promo.minAmount) {
      return res.json({
        success: false,
        valid: false,
        message: `Cần tối thiểu ${promo.minAmount.toLocaleString()}đ để dùng mã này`,
      });
    }

    // Calculate discount
    let discountAmount = 0;
    if (promo.discountType === "percent") {
      discountAmount = Math.floor((amount * promo.discountValue) / 100);
      if (promo.maxDiscount) discountAmount = Math.min(discountAmount, promo.maxDiscount);
    } else {
      discountAmount = promo.discountValue;
    }
    discountAmount = Math.min(discountAmount, amount);

    res.json({
      success: true,
      valid: true,
      promotion: promo,
      discountAmount,
      finalAmount: amount - discountAmount,
      message: `Giảm ${discountAmount.toLocaleString()}đ`,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi kiểm tra mã" });
  }
};
