import { Request, Response } from 'express';
import { Bill, IBill } from '../models/Bill';

export const createBill = async (req: Request, res: Response): Promise<void> => {
  try {
    const newBillData: Partial<IBill> = req.body;

    if (!newBillData.patientId || !newBillData.finalTotalPrice) {
      res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (patientId hoặc finalTotalPrice).'
      });
      return;
    }

    const bill = new Bill(newBillData);
    const savedBill = await bill.save();

    res.status(201).json({
      success: true,
      message: 'Tạo hóa đơn thanh toán thành công!',
      data: savedBill
    });

  } catch (error: any) {
    console.error("❌ Lỗi Controller Bill:", error);
    res.status(500).json({
      success: false,
      message: 'Lỗi hệ thống không thể xử lý hóa đơn.',
      error: error.message
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