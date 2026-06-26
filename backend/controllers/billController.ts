import { Request, Response } from 'express';
import { Bill, IBill } from '../models/Bill';
import mongoose from 'mongoose';
import Inventory from '../models/Inventory';
export const createBill = async (req: Request, res: Response): Promise<void> => {
  // 1. Khởi tạo session để thực hiện Transaction an toàn dữ liệu
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const newBillData: Partial<IBill> = req.body;

    // Kiểm tra các thông tin bắt buộc của hóa đơn giống như Flutter gửi sang
    if (!newBillData.patientId || !newBillData.finalTotalPrice) {
      res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (patientId hoặc finalTotalPrice).'
      });
      await session.abortTransaction();
      session.endSession();
      return;
    }

    // 🟢 ĐÃ ĐỒNG BỘ: Đón nhận chính xác mảng 'medicines' và 'services' từ BillModel của Flutter
    const orderMedicines = req.body.medicines || [];
    const orderServices = req.body.services || [];
    
    if (orderMedicines.length === 0 && orderServices.length === 0) {
      res.status(400).json({
        success: false,
        message: 'Hóa đơn phải chứa ít nhất một dịch vụ hoặc thuốc để thanh toán.'
      });
      await session.abortTransaction();
      session.endSession();
      return;
    }

    // 2. VÒNG LẶP DUYỆT QUA TỪNG THUỐC ĐỂ KHẤU TRỪ LÔ KHO (FIFO) (Chỉ chạy nếu có thuốc)
    if (orderMedicines.length > 0) {
      for (const item of orderMedicines) {
        // 🟢 ĐÃ ĐỒNG BỘ: Ép kiểu 'quantity' từ String (Flutter) sang Number an toàn ở NodeJS
        let requiredQty = parseInt(item.quantity?.toString() || '0', 10); 
        
        // 🟢 ĐÃ ĐỒNG BỘ: Đọc trường 'id' đại diện cho mã thuốc theo đúng cấu trúc BillMedicineItem
        const medicineId = item.id; 
        const medicineName = item.name || 'Thuốc';

        if (!medicineId || requiredQty <= 0) continue;

        // Tìm các lô hàng khả dụng của thuốc này
        const activeBatches = await Inventory.find({
          medicineId: medicineId,
          currentQuantity: { $gt: 0 }, 
          status: 'active',            
          expiryDate: { $gt: new Date() } 
        })
        .sort({ expiryDate: 1 }) // Hạn dùng gần nhất xuất trước
        .session(session);

        // Tính tổng số lượng thực tế hiện có của toàn bộ các lô gộp lại
        const totalAvailable = activeBatches.reduce((sum, b) => sum + b.currentQuantity, 0);
        if (totalAvailable < requiredQty) {
          throw new Error(`Thuốc [${medicineName}] không đủ số lượng trong kho! (Yêu cầu: ${requiredQty}, Hiện có: ${totalAvailable})`);
        }

        // Thực hiện cấu trúc trừ cuốn chiếu số lượng
        for (const batch of activeBatches) {
          if (requiredQty <= 0) break;

          if (batch.currentQuantity >= requiredQty) {
            batch.currentQuantity -= requiredQty;
            requiredQty = 0;
          } else {
            requiredQty -= batch.currentQuantity;
            batch.currentQuantity = 0;
          }

          // Tự động chuyển trạng thái nếu lô hàng cạn kiệt số lượng
          if (batch.currentQuantity === 0) {
            batch.status = 'out_of_stock';
          }

          await batch.save({ session });
        }
      }
    }

    // 3. LƯU HÓA ĐƠN KHI MỌI LOGIC TRỪ KHO ĐÃ HOÀN TẤT VÀ KHÔNG LỖI
    const bill = new Bill(newBillData);
    const savedBill = await bill.save({ session });

    // Áp dụng vĩnh viễn thay đổi vào DB
    await session.commitTransaction();
    session.endSession();

    res.status(201).json({
      success: true,
      message: 'Tạo hóa đơn và khấu trừ lô kho thành công!',
      data: savedBill
    });

  } catch (error: any) {
    // Nếu có sự cố (ví dụ hụt thuốc), khôi phục lại trạng thái ban đầu của kho
    await session.abortTransaction();
    session.endSession();

    console.error("❌ Lỗi Xử Lý Hóa Đơn & Trừ Kho:", error);
    res.status(error.message.includes('không đủ số lượng') ? 400 : 500).json({
      success: false,
      message: error.message || 'Lỗi hệ thống không thể xử lý hóa đơn.',
    });
  }
};

export const getBills = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const search = req.query.search as string;
    
    const skip = (page - 1) * limit;
    
    let queryFilter: any = {};
    if (search) {
      queryFilter.$or = [
        { patientName: { $regex: search, $options: 'i' } },
        { patientId: { $regex: search, $options: 'i' } }
      ];
    }

    const bills = await Bill.find(queryFilter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const totalRecords = await Bill.countDocuments(queryFilter);

    res.status(200).json({
      success: true,
      message: 'Lấy danh sách hóa đơn thành công!',
      data: {
        bills,
        currentPage: page,
        totalPages: Math.ceil(totalRecords / limit),
        totalRecords
      }
    });

  } catch (error: any) {
    console.error("❌ Lỗi hàm getBills:", error);
    res.status(500).json({
      success: false,
      message: 'Lỗi hệ thống không thể lấy danh sách hóa đơn.',
      error: error.message
    });
  }
};

export const getBillById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const bill = await Bill.findById(id);

    if (!bill) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy hóa đơn yêu cầu.'
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Lấy chi tiết hóa đơn thành công!',
      data: bill
    });

  } catch (error: any) {
    console.error("❌ Lỗi hàm getBillById:", error);
    if (error.kind === 'ObjectId') {
      res.status(400).json({
        success: false,
        message: 'Định dạng ID hóa đơn không hợp lệ.'
      });
      return;
    }
    res.status(500).json({
      success: false,
      message: 'Lỗi hệ thống không thể lấy chi tiết hóa đơn.',
      error: error.message
    });
  }
};