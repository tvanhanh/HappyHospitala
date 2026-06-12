import { Request, Response } from 'express';
import { ImportModel } from '../models/ImportMedicine';
import  MedicineModel  from '../models/medicine';

export const createImportMedicne = async (req: Request, res: Response): Promise<void> => {
  try {
    console.log("👉 Dữ liệu nhận từ Flutter:", req.body);
    const { supplierId, note, products, createdBy } = req.body;
    if (!supplierId || !products || !Array.isArray(products) || products.length === 0) {
      res.status(400).json({ success: false, message: 'Danh sách sản phẩm nhập không hợp lệ!' });
      return;
    }

    if (!createdBy) {
      res.status(400).json({ success: false, message: 'Không tìm thấy thông tin người lập phiếu!' });
      return;
    }

    // Tạo mã phiếu nhập tự động (Ví dụ: PN-20260611-171819)
    const now = new Date();
    const dateString = now.toISOString().slice(0, 10).replace(/-/g, '');
    const timeString = now.toTimeString().slice(0, 8).replace(/:/g, '');
    const receiptCode = `PN-${dateString}-${timeString}`;

    let calculatedTotalBill = 0;
    const formattedProducts = []; // Đổi tên biến cho đồng bộ với Schema

    // Duyệt danh sách products gửi từ Flutter
    for (const item of products) {
      const quantity = Number(item.quantity) || 0;
      const importPrice = Number(item.importPrice) || 0;
      const totalPrice = quantity * importPrice;
      
      calculatedTotalBill += totalPrice;

      // Cộng dồn tồn kho trong bảng thuốc (Đảm bảo MedicineModel hoạt động đúng)
      if (item.medicineId) {
        await MedicineModel.findByIdAndUpdate(item.medicineId, {
          $inc: { currentStock: quantity }
        });
      }
      formattedProducts.push({
        medicineId: item.medicineId,
        medicineName: item.medicineName || 'Thuốc không tên',
        quantity: quantity,
        importPrice: importPrice,
        batchNumber: item.batchNumber || 'BATCH-DEFAULT',
        expiryDate: item.expiryDate ? new Date(item.expiryDate) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      });
    }
    const newImportBill = new ImportModel({
      supplierId,
      totalAmount: calculatedTotalBill,
      note: note || null, 
      products: formattedProducts, 
      status: 'Chờ duyệt', 
      createdBy: createdBy
    });

    const savedBill = await newImportBill.save();
    
    // Populate để lấy tên nhà cung cấp trả về cho client hiển thị nếu cần
    const populatedBill = await ImportModel.findById(savedBill._id)
      .populate('supplierId', 'supplierName');

    res.status(201).json({
      success: true,
      message: 'Lập phiếu nhập đa thuốc thành công và kho đã tự động cộng dồn!',
      data: populatedBill
    });

  } catch (error: any) {
    console.error('💥 Lỗi tại createImport Controller:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
export const getImportRecords = async (req: Request, res: Response): Promise<void> => {
  try {
    const imports = await ImportModel.find()
     .populate('supplierId', 'supplierName')
      .sort({ createdAt: -1 }); 

    res.status(200).json({
      success: true,
      message: 'Lấy danh sách phiếu nhập kho thành công!',
      data: imports
    });
    
  } catch (error: any) {
    console.error('💥 Lỗi tại getImportRecords Controller:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi máy chủ không thể lấy danh sách phiếu nhập!',
      error: error.message 
    });
  }
};