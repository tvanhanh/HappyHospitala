import { Request, Response } from 'express';
import { ImportModel } from '../models/ImportMedicine';
import MedicineModel from '../models/medicine';
import Inventory from '../models/Inventory';
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

    let calculatedTotalBill = 0;
    const formattedProducts = [];

    // Duyệt mảng sản phẩm do form Flutter gửi lên
    for (const item of products) {
      const quantity = Number(item.quantity) || 0;
      const importPrice = Number(item.importPrice) || 0;
      const sellingPrice = Number(item.sellingPrice) || 0; // 🔥 Nhận trọn vẹn giá bán của lô thuốc
      const totalPrice = quantity * importPrice;
      
      calculatedTotalBill += totalPrice;

      formattedProducts.push({
        medicineId: item.medicineId,
        medicineName: item.medicineName || 'Thuốc không tên',
        quantity: quantity,
        importPrice: importPrice,
        sellingPrice: sellingPrice, // 🔥 Lưu trữ vào DB phục vụ bước phê duyệt kế tiếp
        totalPrice: totalPrice,
        batchNumber: item.batchNumber || 'BATCH-DEFAULT',
        expiryDate: item.expiryDate ? new Date(item.expiryDate) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      });
    }

    const newImportBill = new ImportModel({
      supplierId,
      totalAmount: calculatedTotalBill,
      note: note || '', 
      products: formattedProducts, // Map mảng products cấu trúc mới
      status: 'Chờ duyệt', 
      createdBy: createdBy
    });

    const savedBill = await newImportBill.save();
    
    const populatedBill = await ImportModel.findById(savedBill._id)
      .populate('supplierId', 'supplierName');

    res.status(201).json({
      success: true,
      message: 'Lập phiếu nhập kho đa thuốc thành công! Vui lòng chờ phê duyệt.',
      data: populatedBill
    });

  } catch (error: any) {
    console.error('💥 Lỗi tại createImport Controller:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. LẤY TOÀN BỘ DANH SÁCH LỊCH SỬ PHIẾU NHẬP
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
    res.status(500).json({ success: false, message: 'Lỗi máy chủ không thể lấy danh sách phiếu nhập!', error: error.message });
  }
};

// 3. PHÊ DUYỆT PHIẾU VÀ CẬP NHẬT GIÁ LÔ VÀO KHO CHI TIẾT (INVENTORY)
export const approveImportBill = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id, status } = req.body;
    if (!id) {
      res.status(400).json({ success: false, message: 'Thiếu ID phiếu nhập kho!' });
      return;
    }

    const importBill = await ImportModel.findById(id);
    if (!importBill) {
      res.status(404).json({ success: false, message: 'Không tìm thấy phiếu nhập kho này.' });
      return;
    }

    // 🟢 HẾT LỖI TS(2367): Do thuộc tính 'status' ở Model giờ đây đã chứa 'Đã duyệt' hợp lệ
    if (importBill.status === 'Đã duyệt') {
      res.status(400).json({ success: false, message: 'Phiếu nhập kho này đã được duyệt trước đó.' });
      return;
    }

    // Cập nhật trạng thái phiếu tổng sang Đã duyệt
    importBill.status = status || 'Đã duyệt';
    await importBill.save();

    const inventoryItems = [];

    // Bóc tách mảng products để đồng bộ tăng kho và cấu hình giá lô chi tiết
    for (const product of importBill.products) {
      
      // A. Cộng dồn số lượng vào tổng kho danh mục gốc (Medicine Model)
      if (product.medicineId) {
        await MedicineModel.findByIdAndUpdate(product.medicineId, {
          $inc: { currentStock: product.quantity }
        });
      }

      // B. Trích xuất chính xác giá bán của riêng lô này sang bảng Inventory chi tiết
      const exportPriceOfBatch = Number(product.sellingPrice || product.importPrice || 0);

      inventoryItems.push({
        medicineId: product.medicineId,
        medicineName: product.medicineName,
        batchNumber: product.batchNumber || 'KHONG_SO_LO',
        importPrice: Number(product.importPrice),
        exportPrice: exportPriceOfBatch, // 🔥 Giá bán đặc thù của lô hàng đã được kích hoạt thành công!
        expiryDate: product.expiryDate,
        originalQuantity: Number(product.quantity),
        currentQuantity: Number(product.quantity), 
        importReceiptId: importBill._id,   
        status: 'active'
      });
    }

    // C. Đẩy dữ liệu hàng loạt vào kho tồn chi tiết
    await Inventory.insertMany(inventoryItems);

    res.status(200).json({ 
      success: true, 
      message: 'Duyệt phiếu, cấu hình giá bán theo lô và cập nhật kho thành công!', 
      data: importBill 
    });

  } catch (error: any) {
    console.error('💥 Lỗi tại approveImportBill Controller:', error);
    res.status(500).json({ success: false, message: 'Có lỗi xảy ra trong quá trình duyệt phiếu', error: error.message });
  }
};