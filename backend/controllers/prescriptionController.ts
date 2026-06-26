import { Request, Response } from 'express';
import { PrescriptionModel, IPrescription } from '../models/prescription';

export const createPrescription = async (req: Request, res: Response): Promise<void | any> => {
  let statusCode = 201;
  let responseData: any = null;

  try {
    console.log("👉 Dữ liệu nhận từ Flutter:", req.body);
    const {
      appointmentId,
      diagnosis,
      patientId,
      patientName,
      patientPhone,
      birthDate,
      gender,
      healthInsurance,
      medicines,
      services,
      doctorId,   
      doctorName,
    }: IPrescription = req.body;

    if (!appointmentId || !diagnosis || !patientId || !patientName) {
      statusCode = 400;
      responseData = {
        success: false,
        message: "Thiếu thông tin bắt buộc! (Lịch hẹn, chẩn đoán, mã BN, tên BN)"
      };
    } else if ((!medicines || medicines.length === 0) && (!services || services.length === 0)) {
      statusCode = 400;
      responseData = {
        success: false,
        message: "Không thể lưu đơn thuốc trống. Vui lòng thêm ít nhất một thuốc hoặc dịch vụ!"
      };
    } else {
      const newPrescription = new PrescriptionModel({
        appointmentId,
        diagnosis,
        patientId,
        patientName,
        patientPhone: patientPhone || null,
        birthDate: birthDate || null,
        gender: gender || null,
        healthInsurance: healthInsurance || null,
        medicines: medicines || [],
        services: services || [],
        status: 'pending',
        doctorId,   
        doctorName
      });

      // Lưu xuống MongoDB
      const savedPrescription = await newPrescription.save();

      responseData = {
        success: true,
        message: "🎉 Đã lưu đơn thuốc vào hệ thống thành công!",
        data: savedPrescription
      };
    }

  } catch (error: any) {
    console.error("💥 Lỗi API createPrescription:", error);
    statusCode = 500;
    responseData = {
      success: false,
      message: "Lỗi máy chủ, không thể xử lý đơn thuốc.",
      error: error.message
    };
  }
  return res.status(statusCode).json(responseData);
};
export const getPrescriptions = async (req: Request, res: Response): Promise<void | any> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const { patientId, appointmentId, status } = req.query;
    const filter: any = {};

    if (patientId) filter.patientId = patientId;
    if (appointmentId) filter.appointmentId = appointmentId;
    if (status) filter.status = String(status);
    const prescriptions = await PrescriptionModel.find(filter).sort({ createdAt: -1 });

    responseData = {
      success: true,
      message: "🎉 Lấy danh sách đơn thuốc thành công!",
      count: prescriptions.length,
      data: prescriptions
    };

  } catch (error: any) {
    console.error("💥 Lỗi API getPrescriptions:", error);
    statusCode = 500;
    responseData = {
      success: false,
      message: "Lỗi máy chủ, không thể lấy danh sách đơn thuốc.",
      error: error.message
    };
  }
  return res.status(statusCode).json(responseData);
};


// =========================================================================
export const getPrescriptionById = async (req: Request, res: Response): Promise<void | any> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const { id } = req.params;

    const prescription = await PrescriptionModel.findById(id);

    if (!prescription) {
      statusCode = 404;
      responseData = {
        success: false,
        message: "Không tìm thấy đơn thuốc yêu cầu hoặc đơn thuốc không tồn tại."
      };
    } else {
      responseData = {
        success: true,
        message: " Tìm thấy chi tiết đơn thuốc!",
        data: prescription
      };
    }

  } catch (error: any) {
    console.error(` Lỗi API getPrescriptionById với ID ${req.params.id}:`, error);
  
    if (error.name === 'CastError') {
      statusCode = 400;
      responseData = {
        success: false,
        message: "Định dạng ID đơn thuốc không hợp lệ."
      };
    } else {
      statusCode = 500;
      responseData = {
        success: false,
        message: "Lỗi máy chủ, không thể lấy thông tin chi tiết đơn thuốc.",
        error: error.message
      };
    }
  }
  return res.status(statusCode).json(responseData);
};
export const updatePrescriptionStatus = async (req: Request, res: Response): Promise<void | any> => {
  let statusCode = 200;
  let responseData: any = null;

  try {
    const { id } = req.params; 
    const { status } = req.body;
    if (!status) {
      statusCode = 400;
      responseData = {
        success: false,
        message: "Vui lòng cung cấp trạng thái (status) mới để cập nhật!"
      };
    } else {
      const updatedPrescription = await PrescriptionModel.findByIdAndUpdate(
        id,
        { status },
        { new: true, runValidators: true }
      );

      if (!updatedPrescription) {
        statusCode = 404;
        responseData = {
          success: false,
          message: "Không tìm thấy đơn thuốc yêu cầu để cập nhật trạng thái."
        };
      } else {
        responseData = {
          success: true,
          message: ` Đã cập nhật trạng thái đơn thuốc sang [${status}] thành công!`,
          data: updatedPrescription
        };
      }
    }

  } catch (error: any) {
    console.error(`Lỗi API updatePrescriptionStatus với ID ${req.params.id}:`, error);
    if (error.name === 'CastError') {
      statusCode = 400;
      responseData = { success: false, message: "Định dạng ID đơn thuốc không hợp lệ." };
    } else {
      statusCode = 500;
      responseData = {
        success: false,
        message: "Lỗi máy chủ, không thể cập nhật trạng thái đơn thuốc.",
        error: error.message
      };
    }
  }

  return res.status(statusCode).json(responseData);
};