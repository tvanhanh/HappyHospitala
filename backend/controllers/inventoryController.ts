import { Request, Response } from 'express';
import mongoose from 'mongoose';
import Inventory from '../models/Inventory'; 

export const getAllInventories = async (req: Request, res: Response): Promise<void> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const inventories = await Inventory.find({ currentQuantity: { $gt: 0 } })
      .populate('medicineId', 'categoryId manufacturer sellingPrice minStock activeIngredient description')
      .sort({ expiryDate: 1 });
    
    responseData = inventories;
  } catch (error: any) {
    statusCode = 500;
    responseData = {
      success: false,
      message: 'Lỗi khi lấy dữ liệu kho hàng',
      error: error.message,
    };
  }

  res.status(statusCode).json(responseData);
  return;
};
export const getInventoryById = async (req: Request, res: Response): Promise<void> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      statusCode = 400;
      responseData = { success: false, message: 'ID kho hàng không hợp lệ' };
    } else {
      const inventoryItem = await Inventory.findById(id);
      
      if (!inventoryItem) {
        statusCode = 404;
        responseData = { success: false, message: 'Không tìm thấy lô hàng này trong kho' };
      } else {
        responseData = inventoryItem;
      }
    }
  } catch (error: any) {
    statusCode = 500;
    responseData = { success: false, error: error.message };
  }

  // ✅ ĐÃ SỬA: Gửi dữ liệu đi và chỉ return rỗng ở cuối để kết thúc hàm (Khớp với Promise<void>)
  res.status(statusCode).json(responseData);
  return;
};

export const addProductsToInventory = async (importReceiptId: string, products: any[]): Promise<boolean> => {
  let isSuccess = false;

  try {
    const inventorySessions = products.map((item) => ({
      medicineId: new mongoose.Types.ObjectId(item.medicineId),
      medicineName: item.medicineName,
      batchNumber: item.batchNumber || `BATCH-${Date.now()}`,
      importPrice: Number(item.importPrice),
      expiryDate: new Date(item.expiryDate),
      originalQuantity: Number(item.quantity),
      currentQuantity: Number(item.quantity),
      importReceiptId: new mongoose.Types.ObjectId(importReceiptId),
      status: 'active' as const
    }));

    await Inventory.insertMany(inventorySessions);
    isSuccess = true;
  } catch (error: any) {
    console.error('💥 Lỗi chèn dữ liệu vào bảng Inventory:', error.message);
    throw new Error(`Lỗi hệ thống khi tự động cập nhật kho: ${error.message}`);
  }

  return isSuccess;
};
export const reduceStockQuantity = async (req: Request, res: Response): Promise<void> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const { inventoryId, quantityToReduce }: { inventoryId: string; quantityToReduce: number } = req.body;

    if (!mongoose.Types.ObjectId.isValid(inventoryId)) {
      statusCode = 400;
      responseData = { success: false, message: 'ID kho hàng không hợp lệ' };
    } else {
      const inventoryItem = await Inventory.findById(inventoryId);
      
      if (!inventoryItem) {
        statusCode = 404;
        responseData = { success: false, message: 'Không tìm thấy lô thuốc trong kho' };
      } else if (inventoryItem.currentQuantity < quantityToReduce) {
        statusCode = 400;
        responseData = {
          success: false,
          message: `Số lượng tồn kho không đủ để xuất! Hiện tại chỉ còn ${inventoryItem.currentQuantity}`,
        };
      } else {
        inventoryItem.currentQuantity -= quantityToReduce;

        if (inventoryItem.currentQuantity === 0) {
          inventoryItem.status = 'out_of_stock';
        }

        await inventoryItem.save();

        responseData = {
          success: true,
          message: 'Trừ số lượng tồn kho thành công',
          data: inventoryItem,
        };
      }
    }
  } catch (error: any) {
    statusCode = 500;
    responseData = { success: false, error: error.message };
  }

  res.status(statusCode).json(responseData);
  return;
};
export const checkMedicinesStock = async (req: Request, res: Response): Promise<void> => {
  try {
    const { medicineIds } = req.body; // Mảng các ID thuốc cần kiểm tra: ["id1", "id2"]

    if (!medicineIds || !Array.isArray(medicineIds)) {
      res.status(400).json({ success: false, message: "Danh sách ID thuốc không hợp lệ." });
      return;
    }
    // Chuyển chuỗi string ID thành ObjectId của Mongoose
    const objectIds = medicineIds.map(id => new mongoose.Types.ObjectId(id));

    // Gom nhóm và tính tổng số lượng tồn kho khả dụng của từng thuốc
    const stockData = await Inventory.aggregate([
      {
        $match: {
          medicineId: { $in: objectIds },
          status: 'active',
          expiryDate: { $gt: new Date() } // Chỉ tính thuốc còn hạn
        }
      },
      {
        $group: {
          _id: "$medicineId",
          totalStock: { $sum: "$currentQuantity" },
          nearestExpiryDate: { $min: "$expiryDate" }, // Lấy ngày hạn dùng gần nhất
          batchNumber: { $first: "$batchNumber" }     // Minh họa lô xuất hiện đầu tiên
        }
      }
    ]);

    res.status(200).json({
      success: true,
      data: stockData
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};