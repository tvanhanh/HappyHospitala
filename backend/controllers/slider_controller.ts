import { Request, Response } from 'express';
import Slider from '../models/Slider';

// Lấy tất cả slider (Admin)
export const getAllSliders = async (req: Request, res: Response): Promise<void> => {
  try {
    const sliders = await Slider.find().sort({ createdAt: -1 }).lean();
    res.status(200).json({ data: sliders });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};

// Lấy slider đang active (Patient)
export const getActiveSliders = async (req: Request, res: Response): Promise<void> => {
  try {
    const sliders = await Slider.find({ isActive: true }).sort({ createdAt: -1 }).lean();
    res.status(200).json({ data: sliders });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};

// Thêm mới slider (với ảnh upload từ Multer-Cloudinary)
export const createSlider = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, subtitle, imageUrl: bodyImageUrl } = req.body;
    let imageUrl = bodyImageUrl || '';

    if (req.file) {
      imageUrl = req.file.path; // Multer-storage-cloudinary trả về secure_url ở path
    }

    if (!imageUrl) {
      res.status(400).json({ message: 'Vui lòng cung cấp hình ảnh slider' });
      return;
    }

    const slider = new Slider({
      imageUrl,
      title: title || '',
      subtitle: subtitle || '',
      isActive: true,
    });

    await slider.save();
    res.status(201).json({ message: 'Thêm slider thành công', data: slider });
  } catch (error) {
    console.error('CREATE SLIDER ERROR:', error);
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};

// Đổi trạng thái hiển thị
export const toggleSlider = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;
    const slider = await Slider.findByIdAndUpdate(
      id,
      { isActive },
      { new: true }
    );
    if (!slider) {
      res.status(404).json({ message: 'Không tìm thấy slider' });
      return;
    }
    res.status(200).json({ message: 'Cập nhật thành công', data: slider });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};

// Xóa slider
export const deleteSlider = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const slider = await Slider.findByIdAndDelete(id);
    if (!slider) {
      res.status(404).json({ message: 'Không tìm thấy slider' });
      return;
    }
    res.status(200).json({ message: 'Xóa thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};

// Cập nhật thông tin slider (title, subtitle, imageUrl)
export const updateSlider = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, subtitle, imageUrl, isActive } = req.body;

    const updateFields: Record<string, unknown> = {};
    if (title !== undefined) updateFields.title = title;
    if (subtitle !== undefined) updateFields.subtitle = subtitle;
    if (imageUrl !== undefined) updateFields.imageUrl = imageUrl;
    if (isActive !== undefined) updateFields.isActive = isActive;

    const slider = await Slider.findByIdAndUpdate(
      id,
      { $set: updateFields },
      { new: true }
    );
    if (!slider) {
      res.status(404).json({ message: 'Không tìm thấy slider' });
      return;
    }
    res.status(200).json({ message: 'Cập nhật thành công', data: slider });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: String(error) });
  }
};
