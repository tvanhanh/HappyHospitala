import { Request, Response } from "express";
import MedicineCategories from "../models/MedicineCategory";
import '../models/MedicineCategory';
export const getAllMedicineCategories = async (req: Request, res: Response) => {
  try {
    const list = await MedicineCategories.find();
 res.status(200).json(list);
 return;
  } catch (error: any) {
  res.status(500).json({ success: false, message: error.message });
  return;
  }
};

export const createMedicineCategory = async (req: Request, res: Response) => {
  try {
    const { categoryname, description } = req.body;

    if (!categoryname) {
    res.status(400).json({ success: false, message: "Vui lòng nhập tên danh mục thuốc!" });
       return;
    }
    // Kiểm tra trùng tên trong bảng danh mục thuốc
    const isExist = await MedicineCategories.findOne({ 
      categoryname: { $regex: new RegExp(`^${categoryname.trim()}$`, "i") } 
    });

    if (isExist) {
      res.status(400).json({ success: false, message: "Danh mục thuốc này đã tồn tại!" });
         return;
    }
    const newCategory = await MedicineCategories.create({ 
      categoryname: categoryname.trim(), 
      description 
    });

  res.status(201).json(newCategory);
     return;
  } catch (error: any) {
   res.status(500).json({ success: false, message: error.message });
      return;
  }
};