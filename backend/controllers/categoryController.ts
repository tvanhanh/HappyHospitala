import { Request, Response } from 'express';
import Category from '../models/category';

export const getAllCategories = async (req: Request, res: Response) => {
  try {
    const categories = await Category.find().sort({ name: 1 });
    res.status(200).json(categories);
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách danh mục thuốc', error: error.message || error });
  }
};

export const createCategory = async (req: Request, res: Response) => {
  try {
    const { categoryCode, name, description } = req.body;
    if (!categoryCode || !name) {
      res.status(400).json({ message: 'Thiếu mã danh mục hoặc tên danh mục' });
      return;
    }
    const newCategory = new Category({ categoryCode, name, description });
    await newCategory.save();
    res.status(201).json({ message: 'Tạo danh mục thuốc thành công', category: newCategory });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi tạo danh mục thuốc', error: error.message || error });
  }
};

export const updateCategory = async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const { categoryCode, name, description } = req.body;
    if (!categoryCode || !name) {
      res.status(400).json({ message: 'Thiếu mã danh mục hoặc tên danh mục' });
      return;
    }
    const updatedCategory = await Category.findByIdAndUpdate(
      id,
      { categoryCode, name, description },
      { new: true }
    );
    if (!updatedCategory) {
      res.status(404).json({ message: 'Không tìm thấy danh mục thuốc' });
      return;
    }
    res.status(200).json({ message: 'Cập nhật danh mục thuốc thành công', category: updatedCategory });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi cập nhật danh mục thuốc', error: error.message || error });
  }
};

export const deleteCategory = async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const deletedCategory = await Category.findByIdAndDelete(id);
    if (!deletedCategory) {
      res.status(404).json({ message: 'Không tìm thấy danh mục thuốc' });
      return;
    }
    res.status(200).json({ message: 'Xóa danh mục thuốc thành công', category: deletedCategory });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi xóa danh mục thuốc', error: error.message || error });
  }
};
