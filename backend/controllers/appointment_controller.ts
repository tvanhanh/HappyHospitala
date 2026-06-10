
import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import Doctor from "../models/Doctor";
import Promotion from "../models/Promotion";
import mongoose from "mongoose";
import { emitToRole, emitToUser } from "../services/socket.service";
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
const ACTIVE_STATUSES = ["confirmed", "checked_in", "in_progress"];
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
      status: { $in: ACTIVE_STATUSES }
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

    // Notify Receptionists
    emitToRole("receptionist", "new_notification", {
      type: "new_appointment",
      title: "Lịch hẹn mới",
      body: `Bệnh nhân ${patientName} đã gửi yêu cầu đặt lịch khám mới lúc ${time} ngày ${date}.`,
      data: appointment,
    });

    // Notify assigned Doctor
    if (doctorRecord && doctorRecord.userId) {
      emitToUser(doctorRecord.userId.toString(), "new_notification", {
        type: "new_appointment",
        title: "Lịch hẹn mới",
        body: `Bạn có lịch hẹn mới từ bệnh nhân ${patientName} lúc ${time} ngày ${date}.`,
        data: appointment,
      });
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
export const updateStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // ✅ Check auth
    if (!req.user) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const user = req.user;

    const validStatus = ["pending", "confirmed", "checked_in", "completed", "cancelled"];

    // ❌ Không cho set missed
    if (status === "missed") {
      res.status(400).json({ message: "Không thể set missed thủ công" });
      return;
    }

    // ❌ Validate status
    if (!validStatus.includes(status)) {
      res.status(400).json({
        success: false,
        message: "Trạng thái không hợp lệ",
      });
      return;
    }

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      res.status(404).json({
        success: false,
        message: "Không tìm thấy lịch hẹn",
      });
      return;
    }

    // ❌ Không update nếu đã kết thúc
    if (["completed", "cancelled", "missed"].includes(appointment.status)) {
      res.status(400).json({
        success: false,
        message: "Lịch đã kết thúc",
      });
      return;
    }

    // ❌ Không update cùng trạng thái
    if (appointment.status === status) {
      res.status(400).json({
        success: false,
        message: "Trạng thái đã là hiện tại",
      });
      return;
    }

    // 🔒 RBAC
    if (status === "confirmed" && user.role !== "receptionist") {
      res.status(403).json({ message: "Chỉ lễ tân được xác nhận" });
      return;
    }

    if (status === "checked_in" && user.role !== "receptionist") {
      res.status(403).json({ message: "Chỉ lễ tân được check-in" });
      return;
    }

    if (status === "completed" && user.role !== "doctor") {
      res.status(403).json({ message: "Chỉ bác sĩ được hoàn thành" });
      return;
    }

    const canCancelRoles = ["receptionist", "patient"];

    if (status === "cancelled" && !canCancelRoles.includes(user.role!)){
      res.status(403).json({ message: "Không có quyền hủy lịch" });
      return;
    }

    // 🔒 Flow
    const validTransitions: Record<string, string[]> = {
      pending: ["confirmed", "cancelled"],
      confirmed: ["checked_in", "cancelled"],
      checked_in: ["completed"],
    };

    if (!validTransitions[appointment.status]?.includes(status)) {
      res.status(400).json({
        success: false,
        message: "Chuyển trạng thái không hợp lệ",
      });
      return;
    }

    // ⏰ Check-in sớm 15p
    if (status === "checked_in") {
      const now = new Date();
      const appointmentTime = new Date(`${appointment.date}T${appointment.time}`);

      const early = new Date(appointmentTime.getTime() - 15 * 60 * 1000);

      if (now < early) {
        res.status(400).json({
          success: false,
          message: "Chỉ được check-in trước 15 phút",
        });
        return;
      }
    }

    // ❌ Không cancel sau check-in
    if (appointment.status === "checked_in" && status === "cancelled") {
      res.status(400).json({
        success: false,
        message: "Không thể hủy sau khi check-in",
      });
      return;
    }

    // ✅ Update
    appointment.status = status;
    await appointment.save();

    // ===== Translate =====
    const statusMap: Record<string, string> = {
      confirmed: "Đã xác nhận",
      cancelled: "Đã hủy",
      completed: "Đã hoàn thành",
      checked_in: "Đã check-in",
      pending: "Chờ xác nhận",
    };

    const statusVietnamese = statusMap[status] || status;

    // ===== Notify Patient =====
    if (appointment.patient) {
      emitToUser(appointment.patient.toString(), "new_notification", {
        type: "appointment_status_changed",
        title: "Trạng thái thay đổi",
        body: `Lịch hẹn ${appointment.time} ${appointment.date}: ${statusVietnamese}`,
        data: appointment,
      });
    }

    // ===== Notify lễ tân =====
    emitToRole("receptionist", "new_notification", {
      type: "appointment_status_changed",
      title: "Cập nhật trạng thái",
      body: `${appointment.patientName} → ${statusVietnamese}`,
      data: appointment,
    });

    res.json({
      success: true,
      message: "Cập nhật thành công",
      data: appointment,
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi server",
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
export const cancelAppointment = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // ✅ Check login
    if (!req.user) {
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const user = req.user;

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      res.status(404).json({
        success: false,
        message: "Không tìm thấy lịch hẹn",
      });
      return;
    }

    // ❌ Không cho hủy nếu đã kết thúc
    if (["completed", "cancelled", "missed"].includes(appointment.status)) {
      res.status(400).json({
        success: false,
        message: "Lịch đã kết thúc, không thể hủy",
      });
      return;
    }

    // 🔒 Phân quyền
    const canCancelRoles = ["receptionist", "patient"];

    if (!canCancelRoles.includes(user.role!)){
      res.status(403).json({
        message: "Không có quyền hủy lịch",
      });
      return;
    }

    // 👤 Nếu là patient → chỉ được hủy lịch của mình
    if (user.role === "patient") {
      if (appointment.patient?.toString() !== user.id){
        res.status(403).json({
          message: "Bạn chỉ được hủy lịch của chính mình",
        });
        return;
      }
    }

    // ❌ Không cho hủy sau khi đã check-in
    if (appointment.status === "checked_in") {
      res.status(400).json({
        success: false,
        message: "Không thể hủy sau khi đã check-in",
      });
      return;
    }

    // ✅ Update
    appointment.status = "cancelled";
    await appointment.save();

    // 🔔 Notify patient
    if (appointment.patient) {
      emitToUser(appointment.patient.toString(), "new_notification", {
        type: "appointment_cancelled",
        title: "Lịch hẹn đã bị hủy",
        body: `Lịch hẹn lúc ${appointment.time} ngày ${appointment.date} đã bị hủy.`,
        data: appointment,
      });
    }

    // 🔔 Notify lễ tân
    emitToRole("receptionist", "new_notification", {
      type: "appointment_cancelled",
      title: "Hủy lịch hẹn",
      body: `${appointment.patientName} đã hủy lịch`,
      data: appointment,
    });

    res.json({
      success: true,
      message: "Hủy lịch thành công",
      data: appointment,
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi server",
    });
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

    // Notify Patient
    if (appointment.patient) {
      emitToUser(appointment.patient.toString(), "new_notification", {
        type: "appointment_status_changed",
        title: "Đã Check-in thành công",
        body: `Lịch hẹn khám lúc ${appointment.time} của bạn đã được Check-in. Vui lòng đợi đến lượt gọi khám.`,
        data: appointment,
      });
    }

    // Notify Doctor
    if (appointment.doctor) {
      const doctorRec = await Doctor.findById(appointment.doctor);
      if (doctorRec && doctorRec.userId) {
        emitToUser(doctorRec.userId.toString(), "new_notification", {
          type: "appointment_status_changed",
          title: "Bệnh nhân đã Check-in",
          body: `Bệnh nhân ${appointment.patientName} (#${(appointment._id as any).toString().slice(-6).toUpperCase()}) đã check-in thành công và đang chờ ở phòng khám.`,
          data: appointment,
        });
      }
    }

    res.json({ success: true, message: "Check-in thành công", data: appointment });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi check-in", error: err });
  }
};
export const getAppointmentStatusChart = async (req: Request, res: Response) =>{
  try {
    // Sử dụng Aggregation Pipeline của MongoDB
    const statusData = await Appointment.aggregate([
      {
        // Bước 1: Nhóm các lịch hẹn lại theo trường 'status'
        $group: {
          _id: "$status", // Lấy giá trị của trường status làm key gom nhóm
          count: { $sum: 1 } // Mỗi lần gặp 1 bản ghi cùng status, cộng thêm 1
        }
      },
      {
        // Bước 2: Đổi tên trường để trả về đúng định dạng Flutter cần
        $project: {
          _id: 0, // 0 nghĩa là KHÔNG trả về trường _id (mặc định của MongoDB)
          name: "$_id", // Gán giá trị _id (chính là tên status) vào trường mới tên là 'name'
          count: 1 // 1 nghĩa là CÓ trả về trường count
        }
      }
    ]);

    // statusData lúc này sẽ có dạng: [ { name: 'pending', count: 5 }, { name: 'completed', count: 10 } ]
    res.status(200).json(statusData);
    
  } catch (error) {
    console.error("Lỗi khi gom nhóm trạng thái lịch hẹn:", error);
    res.status(500).json({ message: "Lỗi Server khi tải dữ liệu biểu đồ" });
  }
};
