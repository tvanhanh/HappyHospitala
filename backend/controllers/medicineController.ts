import { Request, Response } from 'express';
import Medicine from '../models/medicine';

export const addMedicine = async (req: Request, res: Response) => {
  try {
    const {
      medicineCode,
      name,
      activeIngredient,
      categoryId,
      routeOfAdministration,
      unit,
      stockLevel,
      reorderLevel,
      unitPrice,
      expiryDate,
      manufacturer,
    } = req.body;

    if (!medicineCode || !name || !activeIngredient || !categoryId || !routeOfAdministration || !unit || !expiryDate || !manufacturer) {
      res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin thuốc bắt buộc' });
      return;
    }

    const newMedicine = new Medicine({
      medicineCode,
      name,
      activeIngredient,
      categoryId,
      routeOfAdministration,
      unit,
      stockLevel,
      reorderLevel,
      unitPrice,
      expiryDate,
      manufacturer,
    });

    await newMedicine.save();
    res.status(201).json({ message: 'Thêm thuốc mới thành công', medicine: newMedicine });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi thêm thuốc mới', error: error.message || error });
  }
};

export const listMedicines = async (req: Request, res: Response) => {
  try {
    const medicines = await Medicine.find()
      .populate('categoryId')
      .sort({ name: 1 });
    res.status(200).json(medicines);
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách thuốc', error: error.message || error });
  }
};

export const updateMedicine = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      medicineCode,
      name,
      activeIngredient,
      categoryId,
      routeOfAdministration,
      unit,
      stockLevel,
      reorderLevel,
      unitPrice,
      expiryDate,
      manufacturer,
    } = req.body;

    if (!medicineCode || !name || !activeIngredient || !categoryId || !routeOfAdministration || !unit || !expiryDate || !manufacturer) {
      res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin thuốc bắt buộc' });
      return;
    }

    const updatedMedicine = await Medicine.findByIdAndUpdate(
      id,
      {
        medicineCode,
        name,
        activeIngredient,
        categoryId,
        routeOfAdministration,
        unit,
        stockLevel,
        reorderLevel,
        unitPrice,
        expiryDate: new Date(expiryDate),
        manufacturer,
      },
      { new: true }
    );

    if (!updatedMedicine) {
      res.status(404).json({ message: 'Không tìm thấy thuốc' });
      return;
    }

    res.status(200).json({ message: 'Cập nhật thuốc thành công', medicine: updatedMedicine });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi cập nhật thuốc', error: error.message || error });
  }
};

export const deleteMedicine = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const deletedMedicine = await Medicine.findByIdAndDelete(id);

    if (!deletedMedicine) {
      res.status(404).json({ message: 'Không tìm thấy thuốc' });
      return;
    }

    res.status(200).json({ message: 'Xóa thuốc thành công' });
  } catch (error: any) {
    res.status(500).json({ message: 'Lỗi khi xóa thuốc', error: error.message || error });
  }
};

