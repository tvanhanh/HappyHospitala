import { Request, Response } from "express";
import Advertisement from "../models/Advertisement";

export const getAllAds = async (req: Request, res: Response): Promise<any> => {
  try {
    const ads = await Advertisement.find().sort({ priority: -1, createdAt: -1 });
    res.json({ success: true, data: ads });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

export const getActiveAds = async (req: Request, res: Response): Promise<any> => {
  try {
    const { position } = req.query;
    const now = new Date();
    const filter: any = {
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
    };
    if (position) filter.position = position;
    const ads = await Advertisement.find(filter).sort({ priority: -1 });
    // Increment impressions
    await Advertisement.updateMany({ _id: { $in: ads.map((a) => a._id) } }, { $inc: { impressionCount: 1 } });
    res.json({ success: true, data: ads });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

export const createAd = async (req: any, res: Response): Promise<any> => {
  try {
    const ad = await Advertisement.create({ ...req.body, createdBy: req.user?.id });
    res.status(201).json({ success: true, data: ad, message: "Tạo quảng cáo thành công" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi tạo quảng cáo" });
  }
};

export const updateAd = async (req: Request, res: Response): Promise<any> => {
  try {
    const ad = await Advertisement.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!ad) return res.status(404).json({ success: false, message: "Không tìm thấy" });
    res.json({ success: true, data: ad });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi cập nhật" });
  }
};

export const deleteAd = async (req: Request, res: Response): Promise<any> => {
  try {
    await Advertisement.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Đã xóa quảng cáo" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi xóa" });
  }
};

export const trackAdClick = async (req: Request, res: Response): Promise<any> => {
  try {
    await Advertisement.findByIdAndUpdate(req.params.id, { $inc: { clickCount: 1 } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false });
  }
};
