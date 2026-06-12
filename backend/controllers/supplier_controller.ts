import { Request, Response } from 'express';
import { Supplier } from '../models/supplier';

// 1. TẠO MỚI NHÀ CUNG CẤP (Create)
export const createSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const { supplierName, contactName, phone, email, supplierType, status, address, note } = req.body;

    // Kiểm tra trùng số điện thoại
    const existingSupplier = await Supplier.findOne({ phone: phone.trim() });
    if (existingSupplier) {
      res.status(400).json({ 
        success: false, 
        message: 'Số điện thoại nhà cung cấp này đã tồn tại trong hệ thống!' 
      });
      return;
    }

    const newSupplier = new Supplier({
      supplierName,
      contactName,
      phone,
      email,
      supplierType,
      status,
      address,
      note
    });

    const savedSupplier = await newSupplier.save();
    res.status(201).json({ success: true, data: savedSupplier });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Lỗi khi tạo nhà cung cấp', error: error.message });
  }
};

// 2. LẤY TOÀN BỘ DANH SÁCH (Read All)
export const getAllSuppliers = async (req: Request, res: Response): Promise<void> => {
  try {
    const suppliers = await Supplier.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: suppliers.length, data: suppliers });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Lỗi khi lấy danh sách nhà cung cấp', error: error.message });
  }
};

// 3. CẬP NHẬT THÔNG TIN (Update)
export const updateSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const updatedData = req.body;

    const updatedSupplier = await Supplier.findByIdAndUpdate(
      id,
      { $set: updatedData },
      { new: true, runValidators: true }
    );

    if (!updatedSupplier) {
      res.status(404).json({ success: false, message: 'Không tìm thấy nhà cung cấp' });
      return;
    }

    res.status(200).json({ success: true, data: updatedSupplier });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Lỗi khi cập nhật thông tin', error: error.message });
  }
};

// 4. XÓA NHÀ CUNG CẤP (Delete)
export const deleteSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const deletedSupplier = await Supplier.findByIdAndDelete(id);

    if (!deletedSupplier) {
      res.status(404).json({ success: false, message: 'Không tìm thấy nhà cung cấp để xóa' });
      return;
    }

    res.status(200).json({ success: true, message: 'Xóa nhà cung cấp thành công thành công!' });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Lỗi khi xóa nhà cung cấp', error: error.message });
  }
};