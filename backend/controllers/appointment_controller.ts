import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import Doctor from "../models/Doctor";
import Promotion from "../models/Promotion";
import mongoose from "mongoose";

/**
 * ================= CREATE APPOINTMENT =================
 * patient lấy từ JWT
 * doctor lấy từ body
 * 
 * [RACE CONDITION GUARD]
 * Sử dụng MongoDB unique index trên {doctor, date, time} để đảm bảo
 * chỉ 1 booking được tạo cho mỗi slot, ngay cả khi 2 request đến đồng thời.
 * Nếu trùng slot, MongoDB ném lỗi duplicate key (code 11000).
 */
export const addAppointment = async (req: any, res: Response): Promise<void> => {
  try {
    const patientId = req.user.id;

    const {
      doctor,
      department,
      patientName,
      phone,
      cccd,
      gender,
      birthDate,
      address,
      medicalHistory,
      allergies,
      reason,
      date,
      time,
      imageUrl,
      promotionCode,
      insuranceNumber,
    } = req.body;

    // ================= VALIDATION =================
    if (!doctor || !reason || !date || !time || !department) {
      res.status(400).json({
        success: false,
        message: "Thiếu dữ liệu bắt buộc",
      });
      return;
    }

    // ── [STEP 1] Pre-check: Kiểm tra slot có sẵn không (nhanh, trước khi tạo) ──
    // Chặn khoảng 15 phút (1 ca khám): không cho đặt nếu đã có lịch trong cùng khoảng thời gian
    const existingSlot = await Appointment.findOne({
      doctor,
      date,
      time,
      status: { $in: ["pending", "confirmed", "checked_in", "completed"] }
    });

    if (existingSlot) {
      res.status(409).json({
        success: false,
        slotConflict: true,
        message: "Ca khám " + time + " ngày " + date + " đã được đặt. Vui lòng chọn giờ khác.",
      });
      return;
    }

    // ── [STEP 2] Calculate Fee ──
    const doctorRecord = await Doctor.findById(doctor);
    const originalFee = doctorRecord?.consultationFee || 0;
    let finalFee = originalFee;
    let discountAmount = 0;
    let insuranceCoverage = 0;
    let paymentMethod = req.body.paymentMethod || "cash";

    if (insuranceNumber) {
      // BHYT mặc định cover 80% phí khám
      insuranceCoverage = 80;
      discountAmount = (originalFee * insuranceCoverage) / 100;
      finalFee = originalFee - discountAmount;
      paymentMethod = "insurance";
    }

    if (promotionCode) {
      const promo = await Promotion.findOne({ code: promotionCode.trim().toUpperCase(), isActive: true });
      if (promo) {
        let promoDiscount = promo.discountType === "percent"
          ? (originalFee * promo.discountValue) / 100
          : promo.discountValue;
        
        if (promo.maxDiscount) promoDiscount = Math.min(promoDiscount, promo.maxDiscount);
        
        discountAmount += promoDiscount;
        finalFee -= promoDiscount;
        
        // Cập nhật số lần dùng promo
        await Promotion.updateOne({ _id: promo._id }, { $inc: { usedCount: 1 } });
      }
    }
    
    finalFee = Math.max(0, finalFee); // Không để phí bị âm

    // ── [STEP 3] Atomic create — tạo appointment (MongoDB unique index sẽ chặn race condition) ──
    let appointment;
    try {
      appointment = await Appointment.create({
        patient: patientId,
        doctor,
        departmentId: department,
        patientName,
        phone,
        cccd,
        gender,
        birthDate,
        address,
        medicalHistory,
        allergies,
        reason,
        date,
        time,
        imageUrl: imageUrl || "",
        status: "pending",
        originalFee,
        discountAmount,
        insuranceCoverage,
        insuranceNumber,
        finalFee,
        promotionCode,
        paymentMethod,
        isPaid: false,
      });
    } catch (createErr: any) {
      // MongoDB duplicate key error — 2 người đặt cùng lúc, người thứ 2 sẽ bị từ chối
      if (createErr.code === 11000) {
        res.status(409).json({
          success: false,
          slotConflict: true,
          message: "Ca khám " + time + " vừa được người khác đặt. Hệ thống đã tự động hủy giao dịch của bạn. Vui lòng chọn giờ khác.",
        });
        return;
      }
      throw createErr;
    }

    res.status(201).json({
      success: true,
      message: "Tạo lịch hẹn thành công",
      data: appointment,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi tạo lịch hẹn",
      error: err,
    });
  }
};


/**
 * ================= GET DOCTOR APPOINTMENTS =================
 */
export const getDoctorAppointments = async (req: any, res: Response): Promise<void> => {
  try {
    const doctorProfile = await Doctor.findOne({ userId: req.user.id });
    if (!doctorProfile) {
      res.status(404).json({
        success: false,
        message: "Không tìm thấy hồ sơ bác sĩ",
      });
      return;
    }
    const appointments = await Appointment.find({
      doctor: doctorProfile._id,
    })
      .populate({
        path: "doctor",
        populate: {
          path: "userId",
          select: "fullName avatar phoneNumber email role status",
        }
      })
      .populate("patient", "fullName avatar phoneNumber email")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
    });
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};

/**
 * ================= GET ALL (ADMIN) =================
 */
export const getAllAppointments = async (req: any, res: Response): Promise<void> => {
  try {
    const appointments = await Appointment.find()
      .populate({
        path: "doctor",
        populate: {
          path: "userId",
          select: "fullName avatar phoneNumber email role status",
        }
      })
      .populate("patient", "fullName avatar phoneNumber email")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
    });
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};
export const getMyAppointments = async (req: any, res: Response): Promise<void> => {
  try {
    const patientId = new mongoose.Types.ObjectId(req.user.id);
    
    // Debug log
    console.log("req.user.id =", req.user.id);
    console.log("type =", typeof req.user.id);

    const appointments = await Appointment.find({
      patient: patientId,
    })
      // 1. Populate lồng nhau cho Doctor -> User để lấy thông tin mới
      .populate({
        path: "doctor",
        populate: {
          path: "userId", 
          select: "fullName avatar phoneNumber email role status", // Cập nhật các trường ở cấp root
        }
      })
      // 2. Populate cho Patient (Giả sử patient tham chiếu trực tiếp đến bảng User)
      .populate("patient", "fullName avatar phoneNumber email") 
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
    });
    
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};
/**
 * ================= UPDATE STATUS =================
 */
export const updateStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const updated = await Appointment.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    );

    res.json({
      success: true,
      message: "Update status success",
      data: updated,
    });
    console.log("UPDATE STATUS HIT");
console.log(req.params);
console.log(req.body);
  } catch (err) {
    res.status(500).json({ message: "Error" });
  }
};

/**
 * ================= DELETE APPOINTMENT =================
 */
export const cancelAppointment = async (req: Request, res: Response) => {
  try {
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      { status: "cancelled" },
      { new: true }
    );

    res.json({
      success: true,
      data: appointment,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Huỷ lịch thất bại",
    });
  }

  
};
// Lấy theo Ngày
export const getAppointmentsByDate = async (req: Request, res: Response) => {
  try {
    let date = req.query.date as string; 
    console.log("Date:", date);
    if (!date) {
      const today = new Date();
      const offset = today.getTimezoneOffset();
      const localToday = new Date(today.getTime() - (offset * 60 * 1000));
      date = localToday.toISOString().split('T')[0];
    }
    const appointments = await Appointment.find({
      date: date,
    })
      .populate({
        path: "doctor",
        populate: {
          path: "userId",
          select: "fullName avatar phoneNumber email role status",
        }
      })
      .populate("patient", "fullName avatar phoneNumber email")
      .populate("departmentId", "departmentName")
      .sort({ time: 1 });

    res.json({
      success: true,
      data: appointments,
    });
    return;
  } catch (err) {
   res.status(500).json({
      success: false,
      message: "Lỗi server",
      error: err,
    });
    return;
  }
};

// Lấy danh sách giờ đã đặt — dùng để ẩn slot đã book khỏi UI
export const getBookedSlots = async (req: Request, res: Response) => {
  try {
    const { doctorId, date } = req.query;
    if (!doctorId || !date) {
      res.status(400).json({
        success: false,
        message: "Thiếu doctorId hoặc date",
      });
      return;
    }
    // Bao gồm checked_in để block luôn những ca đã check-in
    const appointments = await Appointment.find({
      doctor: doctorId,
      date: date,
      status: { $in: ["pending", "confirmed", "checked_in", "completed"] }
    }).select("time");
    
    const bookedTimes = appointments.map(a => a.time);
    res.json({
      success: true,
      data: bookedTimes,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi server khi lấy slots",
      error: err,
    });
  }
};

/**
 * ================= CHECK SLOT AVAILABILITY (Pre-submit validation) =================
 * Frontend gọi trước khi submit để confirm slot vẫn còn trống.
 * Trả về { available: true/false } để UI có thể cảnh báo user.
 */
export const checkSlotAvailability = async (req: Request, res: Response) => {
  try {
    const { doctorId, date, time } = req.query;
    if (!doctorId || !date || !time) {
      res.status(400).json({ success: false, message: "Thiếu tham số" });
      return;
    }
    const existing = await Appointment.findOne({
      doctor: doctorId,
      date: date,
      time: time,
      status: { $in: ["pending", "confirmed", "checked_in", "completed"] }
    });
    res.json({
      success: true,
      available: !existing,
      message: existing ? "Slot đã được đặt" : "Slot còn trống",
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi server" });
  }
};

/**
 * ================= CHECK-IN (Receptionist verifies Booking ID) =================
 * Cập nhật status → checked_in khi bệnh nhân đến phòng khám.
 */
export const checkInAppointment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const appointment = await Appointment.findById(id);
    if (!appointment) {
      res.status(404).json({ success: false, message: "Không tìm thấy lịch hẹn" });
      return;
    }
    if (!["pending", "confirmed"].includes(appointment.status)) {
      res.status(400).json({ success: false, message: "Lịch hẹn không hợp lệ để check-in" });
      return;
    }
    appointment.status = "checked_in";
    await appointment.save();
    res.json({ success: true, message: "Check-in thành công", data: appointment });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi check-in", error: err });
  }
};
