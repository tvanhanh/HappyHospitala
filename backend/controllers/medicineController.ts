import { Request, Response } from 'express';

import MedicineModel from '../models/medicine';
export const createMedicine = async (req: Request, res: Response): Promise<void> => {
  try {
    const medicineCode = 'MED-' + Date.now();
    const { 
      medicineName, 
      categoryId, 
      supplierId, 
      dosage, 
      unit, 
      manufacturer, 
      sellingPrice, 
      minStock,    
      imageUrl,   
      description, 
      status 
    } = req.body;

    if (!medicineName || !categoryId || !supplierId || !dosage || !manufacturer || sellingPrice === undefined || minStock === undefined) {
      res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ các trường dữ liệu bắt buộc (*), bao gồm Giá bán và Tồn kho tối thiểu',
      });
      return; 
    }

    const newMedicine = new MedicineModel({
      medicineCode,
      medicineName,
      categoryId,
      supplierId,
      dosage,
      unit,
      manufacturer,
      sellingPrice, 
      minStock,     
      imageUrl: imageUrl || '', 
      description,
      status,
    });

    const savedMedicine = await newMedicine.save();
    res.status(201).json({ 
      success: true, 
      message: 'Thêm thuốc mới thành công!',
      data: savedMedicine 
    });
  } catch (error: any) {
    console.error('💥 Lỗi tại createMedicine Controller:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi hệ thống không thể thêm thuốc', 
      error: error.message 
    });
  }
};

// 2. LẤY TOÀN BỘ DANH SÁCH THUỐC (Read All)
// Đường dẫn map với Flutter: /api/auth/get_medicines
export const getAllMedicines = async (req: Request, res: Response): Promise<void> => {
  try {
    const medicines = await MedicineModel.find()
      .populate('categoryId', 'categoryName') 
      .populate('supplierId', 'supplierName phone') 
      .sort({ createdAt: -1 }); 

    res.status(200).json({ 
      success: true, 
      count: medicines.length, 
      data: medicines 
    });
  } catch (error: any) {
    console.error('💥 Lỗi tại getAllMedicines Controller:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi hệ thống không thể lấy danh sách thuốc', 
      error: error.message 
    });
  }
};

// 3. CẬP NHẬT THÔNG TIN THUỐC (Update)
export const updateMedicine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const updatedData = req.body; // Nhận cục body (gồm cả trường mới nếu Flutter truyền lên để sửa)

    const updatedMedicine = await MedicineModel.findByIdAndUpdate(
      id,
      { $set: updatedData },
      { new: true, runValidators: true } // runValidators: true giúp ép kiểu validate của Schema khi cập nhật
    );

    if (!updatedMedicine) {
      res.status(404).json({ success: false, message: 'Không tìm thấy thông tin loại thuốc cần cập nhật' });
      return;
    }

    res.status(200).json({ success: true, data: updatedMedicine });
  } catch (error: any) {
    console.error('💥 Lỗi tại updateMedicine Controller:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi khi cập nhật thông tin thuốc', 
      error: error.message 
    });
  }
};

// 4. XÓA THUỐC (Delete)
// Đường dẫn map với Flutter: /api/auth/delete_medicine/:id
export const deleteMedicine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const deletedMedicine = await MedicineModel.findByIdAndDelete(id);

    if (!deletedMedicine) {
      res.status(404).json({ success: false, message: 'Không tìm thấy thuốc yêu cầu xóa hoặc ID không hợp lệ' });
      return;
    }

    res.status(200).json({ success: true, message: `Đã xóa thành công thuốc: ${deletedMedicine.medicineName}` });
  } catch (error: any) {
    console.error('💥 Lỗi tại deleteMedicine Controller:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi hệ thống không thể xóa đối tượng thuốc', 
      error: error.message 
    });
  }
};
// import Medicine from '../models/medicine';

// export const addMedicine = async (req: Request, res: Response) => {
//   try {
//     const {
//       medicineCode,
//       name,
//       activeIngredient,
//       categoryId,
//       routeOfAdministration,
//       unit,
//       stockLevel,
//       reorderLevel,
//       unitPrice,
//       expiryDate,
//       manufacturer,
//     } = req.body;

//     if (!medicineCode || !name || !activeIngredient || !categoryId || !routeOfAdministration || !unit || !expiryDate || !manufacturer) {
//       res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin thuốc bắt buộc' });
//       return;
//     }

//     const newMedicine = new Medicine({
//       medicineCode,
//       name,
//       activeIngredient,
//       categoryId,
//       routeOfAdministration,
//       unit,
//       stockLevel,
//       reorderLevel,
//       unitPrice,
//       expiryDate,
//       manufacturer,
//     });

//     await newMedicine.save();
//     res.status(201).json({ message: 'Thêm thuốc mới thành công', medicine: newMedicine });
//   } catch (error: any) {
//     res.status(500).json({ message: 'Lỗi khi thêm thuốc mới', error: error.message || error });
//   }
// };

// export const listMedicines = async (req: Request, res: Response) => {
//   try {
//     const medicines = await Medicine.find()
//       .populate('categoryId')
//       .sort({ name: 1 });
//     res.status(200).json(medicines);
//   } catch (error: any) {
//     res.status(500).json({ message: 'Lỗi khi lấy danh sách thuốc', error: error.message || error });
//   }
// };

// export const updateMedicine = async (req: Request, res: Response) => {
//   try {
//     const { id } = req.params;
//     const {
//       medicineCode,
//       name,
//       activeIngredient,
//       categoryId,
//       routeOfAdministration,
//       unit,
//       stockLevel,
//       reorderLevel,
//       unitPrice,
//       expiryDate,
//       manufacturer,
//     } = req.body;

//     if (!medicineCode || !name || !activeIngredient || !categoryId || !routeOfAdministration || !unit || !expiryDate || !manufacturer) {
//       res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin thuốc bắt buộc' });
//       return;
//     }

//     const updatedMedicine = await Medicine.findByIdAndUpdate(
//       id,
//       {
//         medicineCode,
//         name,
//         activeIngredient,
//         categoryId,
//         routeOfAdministration,
//         unit,
//         stockLevel,
//         reorderLevel,
//         unitPrice,
//         expiryDate: new Date(expiryDate),
//         manufacturer,
//       },
//       { new: true }
//     );

//     if (!updatedMedicine) {
//       res.status(404).json({ message: 'Không tìm thấy thuốc' });
//       return;
//     }

//     res.status(200).json({ message: 'Cập nhật thuốc thành công', medicine: updatedMedicine });
//   } catch (error: any) {
//     res.status(500).json({ message: 'Lỗi khi cập nhật thuốc', error: error.message || error });
//   }
// };

// export const deleteMedicine = async (req: Request, res: Response) => {
//   try {
//     const { id } = req.params;
//     const deletedMedicine = await Medicine.findByIdAndDelete(id);

//     if (!deletedMedicine) {
//       res.status(404).json({ message: 'Không tìm thấy thuốc' });
//       return;
//     }

//     res.status(200).json({ message: 'Xóa thuốc thành công' });
//   } catch (error: any) {
//     res.status(500).json({ message: 'Lỗi khi xóa thuốc', error: error.message || error });
//   }
// };

