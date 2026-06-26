import { Request, Response } from 'express';
import DoctorSchedule from '../models/DoctorSchedule';
import Doctor from '../models/Doctor';
import Room from '../models/Room';

export const assignDoctorSchedule = async (req: Request, res: Response): Promise<void> => {
  try {
    const { doctorId, roomId, date, shift } = req.body;

    // --- LỚP BẢO VỆ 1 (BUSINESS LOGIC VALIDATION): CHECK TRÙNG LỊCH ---
    
    // a. Check xem bác sĩ này đã có lịch ở phòng khác trong cùng Ca/Ngày này chưa?
    const existingDoctorSchedule = await DoctorSchedule.findOne({ 
      doctorId, 
      date: new Date(date), // Nên chuẩn hóa date về 0h để query chính xác
      shift 
    });
    
    if (existingDoctorSchedule) {
      res.status(409).json({ message: 'Lỗi: Bác sĩ này đã được xếp lịch ở một phòng khám khác trong ca này!' });
      return;
    }

    // b. Check xem phòng khám này đã được gán cho bác sĩ khác trong cùng Ca/Ngày này chưa?
    const existingRoomSchedule = await DoctorSchedule.findOne({ 
      roomId, 
      date: new Date(date), 
      shift 
    });
    
    if (existingRoomSchedule) {
      res.status(409).json({ message: 'Lỗi: Phòng khám này đã được gán cho một bác sĩ khác trong ca này!' });
      return;
    }
// --- LỚP BẢO VỆ 2 (DATA INTEGRITY VALIDATION): CHECK SAI CHUYÊN KHOA ---
    
    // Tìm kiếm thông minh: Thử tìm theo Doctor ID trước, nếu không có thì tìm theo User ID
    let doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      doctor = await Doctor.findOne({ userId: doctorId });
    }

    const room = await Room.findById(roomId);

    if (!doctor || !room) {
      res.status(404).json({ message: 'Lỗi: Bác sĩ hoặc Phòng khám không tồn tại trong hệ thống!' });
      return;
    }

    // 1. Kiểm tra xem bác sĩ đã có chuyên khoa trong hồ sơ chưa
    if (!doctor.specialtyId) {
      res.status(400).json({ 
        message: 'Lỗi: Hồ sơ bác sĩ này chưa được cập nhật Chuyên khoa! Vui lòng cập nhật hồ sơ bác sĩ trước khi xếp lịch.' 
      });
      return;
    }

    if (!room.specialtyId) {
      res.status(400).json({ 
        message: 'Lỗi: Hồ sơ phòng khám này chưa được cập nhật Chuyên khoa! Vui lòng cập nhật hồ sơ phòng khám trước khi xếp lịch.' 
      });
      return;
    }

    // 2. So sánh: Chuyên khoa của Bác sĩ PHẢI khớp với Chuyên khoa của Phòng
    if (doctor.specialtyId.toString() !== room.specialtyId.toString()) {
      res.status(400).json({ 
        message: 'Lỗi nghiêm trọng: Bác sĩ này không thuộc chuyên khoa phù hợp với phòng khám này!'
      });
      return;
    }

    // --- LỚP BẢO VỆ 3 (DATABASE VALIDATION) ---

    // LƯU Ý: Phải lưu doctor._id (ID của bảng Doctor) vào lịch trực để sau này populate không bị lỗi
    const newSchedule = new DoctorSchedule({
      doctorId: doctor._id, 
      roomId,
      specialtyId: room.specialtyId, 
      date: new Date(date),
      shift,
    });

    const savedSchedule = await newSchedule.save();
    res.status(201).json(savedSchedule);

  } catch (error: any) {
    // Nếu UNIQUE INDEX ở Model chặn lại, nó sẽ quăng vào catch này
    if (error.code === 11000) {
      res.status(409).json({ message: 'Lỗi: Trùng lịch trực! (Bác sĩ hoặc Phòng đã được xếp trong ca này)' });
    } else {
      res.status(400).json({ message: error.message });
    }
  }
};

export const getSchedulesByDate = async (req: Request, res: Response): Promise<void> => {
  try {
    const { date } = req.query;

    if (!date) {
      res.status(400).json({ message: 'Vui lòng truyền tham số date (Ví dụ: ?date=2026-06-25)' });
      return;
    }

    // Chuẩn hóa ngày về 00:00:00 để query khớp hoàn toàn với dữ liệu đã lưu
    const queryDate = new Date(date as string);
    queryDate.setUTCHours(0, 0, 0, 0);

    // Lấy lịch và Deep Populate (Kéo sâu 2 tầng để lấy fullName và avatar)
    const schedules = await DoctorSchedule.find({ date: queryDate })
      .populate({
        path: 'doctorId',
        populate: { 
           path: 'userId', 
           select: 'fullName avatar email' // Moi thẳng tên và ảnh từ bảng User
        } 
      })
      .populate('roomId', 'roomNumber floor status')
      .populate('specialtyId', 'name')
      .sort({ shift: 1 });
    res.status(200).json(schedules);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// --- LẤY LỊCH TRỰC CỦA 1 BÁC SĨ TỪ HÔM NAY ---
export const getDoctorSchedules = async (req: Request, res: Response): Promise<void> => {
  try {
    const { doctorId } = req.params;

    // Chỉ lấy lịch từ hôm nay trở đi
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);

    const schedules = await DoctorSchedule.find({ 
      doctorId,
      status: 'active',
      date: { $gte: today } 
    }).sort({ date: 1, shift: 1 });

    res.status(200).json(schedules);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
// --- HÀM SỬA LỊCH TRỰC (PUT) ---
export const updateSchedule = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { doctorId, roomId, date, shift, timeSlotDuration, maxPatients, status } = req.body;

    // Chuẩn hóa ngày về 0h
    const scheduleDate = new Date(date);
    scheduleDate.setUTCHours(0, 0, 0, 0);

    // 1. Kiểm tra lịch có tồn tại không
    const existingSchedule = await DoctorSchedule.findById(id);
    if (!existingSchedule) {
      res.status(404).json({ message: 'Lỗi: Không tìm thấy lịch trực này!' });
      return;
    }

    // --- LỚP BẢO VỆ 1: CHECK TRÙNG LỊCH (NHƯNG BỎ QUA CHÍNH NÓ) ---
    const doctorConflict = await DoctorSchedule.findOne({
      _id: { $ne: id }, // Bỏ qua cái ID đang sửa
      doctorId,
      date: scheduleDate,
      shift
    });
    if (doctorConflict) {
      res.status(409).json({ message: 'Lỗi: Bác sĩ này đã có lịch ở phòng khác trong ca này!' });
      return;
    }

    const roomConflict = await DoctorSchedule.findOne({
      _id: { $ne: id }, // Bỏ qua cái ID đang sửa
      roomId,
      date: scheduleDate,
      shift
    });
    if (roomConflict) {
      res.status(409).json({ message: 'Lỗi: Phòng khám này đã được gán cho bác sĩ khác trong ca này!' });
      return;
    }

    // --- LỚP BẢO VỆ 2: CHECK SAI CHUYÊN KHOA ---
    let doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      doctor = await Doctor.findOne({ userId: doctorId });
    }

    const room = await Room.findById(roomId);

    if (!doctor || !room) {
      res.status(404).json({ message: 'Lỗi: Bác sĩ hoặc Phòng khám không tồn tại!' });
      return;
    }
    if (!doctor.specialtyId || !room.specialtyId) {
      res.status(400).json({ message: 'Lỗi: Thiếu thông tin Chuyên khoa của Bác sĩ hoặc Phòng khám.' });
      return;
    }
    if (doctor.specialtyId.toString() !== room.specialtyId.toString()) {
      res.status(400).json({ message: 'Lỗi nghiêm trọng: Bác sĩ không khớp chuyên khoa với phòng!' });
      return;
    }

    // --- TIẾN HÀNH CẬP NHẬT ---
    const updatedSchedule = await DoctorSchedule.findByIdAndUpdate(
      id,
      {
        doctorId: doctor._id, // Đồng bộ lưu ID của bảng Doctor
        roomId,
        specialtyId: room.specialtyId,
        date: scheduleDate,
        shift,
        ...(timeSlotDuration && { timeSlotDuration }),
        ...(maxPatients && { maxPatients }),
        ...(status && { status })
      },
      { new: true, runValidators: true }
    );
    // --- TIẾN HÀNH CẬP NHẬT ---
    res.status(200).json(updatedSchedule);
  } catch (error: any) {
    if (error.code === 11000) {
      res.status(409).json({ message: 'Lỗi: Trùng lặp dữ liệu trong hệ thống!' });
    } else {
      res.status(500).json({ message: error.message });
    }
  }
};

// --- HÀM XÓA LỊCH TRỰC (DELETE) ---
export const deleteSchedule = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const deletedSchedule = await DoctorSchedule.findByIdAndDelete(id);
    
    if (!deletedSchedule) {
      res.status(404).json({ message: 'Lỗi: Không tìm thấy lịch trực này để xóa!' });
      return;
    }

    res.status(200).json({ message: 'Xóa lịch trực thành công!' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
// --- HÀM SAO CHÉP LỊCH TRỰC (POST /copy) ---
// Hỗ trợ 3 mode: 'day' | 'week' | 'month'
// Chiến lược: SKIP (bỏ qua ca trùng, không làm hỏng toàn batch)
export const copySchedule = async (req: Request, res: Response): Promise<void> => {
  try {
    const { fromDate, toDate, type } = req.body;

    if (!fromDate || !toDate || !type) {
      res.status(400).json({ message: 'Thiếu tham số: fromDate, toDate, type (day|week|month)' });
      return;
    }

    if (!['day', 'week', 'month'].includes(type)) {
      res.status(400).json({ message: 'type phải là một trong: day, week, month' });
      return;
    }

    const sourceStart = new Date(fromDate);
    sourceStart.setUTCHours(0, 0, 0, 0);
    const targetStart = new Date(toDate);
    targetStart.setUTCHours(0, 0, 0, 0);

    // ---- Xây dựng danh sách cặp ngày [sourceDate, targetDate] cần copy ----
    const datePairs: Array<{ source: Date; target: Date }> = [];

    if (type === 'day') {
      datePairs.push({ source: sourceStart, target: targetStart });

    } else if (type === 'week') {
      // Căn về thứ 2 đầu tuần của ngày được chọn (ISO week: Mon=1)
      const getMonday = (d: Date): Date => {
        const date = new Date(d);
        const day = date.getUTCDay(); // 0=Sun, 1=Mon...
        const diff = day === 0 ? -6 : 1 - day; // Lùi về thứ 2
        date.setUTCDate(date.getUTCDate() + diff);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      };
      const sourceMonday = getMonday(sourceStart);
      const targetMonday = getMonday(targetStart);

      for (let i = 0; i < 7; i++) {
        const src = new Date(sourceMonday);
        src.setUTCDate(src.getUTCDate() + i);
        const tgt = new Date(targetMonday);
        tgt.setUTCDate(tgt.getUTCDate() + i);
        datePairs.push({ source: src, target: tgt });
      }

    } else if (type === 'month') {
      // Lấy tháng + năm từ fromDate và toDate
      const srcYear = sourceStart.getUTCFullYear();
      const srcMonth = sourceStart.getUTCMonth(); // 0-indexed
      const tgtYear = targetStart.getUTCFullYear();
      const tgtMonth = targetStart.getUTCMonth();

      const daysInSrcMonth = new Date(Date.UTC(srcYear, srcMonth + 1, 0)).getUTCDate();
      const daysInTgtMonth = new Date(Date.UTC(tgtYear, tgtMonth + 1, 0)).getUTCDate();

      for (let day = 1; day <= daysInSrcMonth; day++) {
        // Bỏ qua ngày không tồn tại ở tháng đích (VD: ngày 31 tháng 2)
        if (day > daysInTgtMonth) continue;

        const src = new Date(Date.UTC(srcYear, srcMonth, day));
        const tgt = new Date(Date.UTC(tgtYear, tgtMonth, day));
        datePairs.push({ source: src, target: tgt });
      }
    }

    // ---- Thực hiện sao chép từng cặp ngày ----
    let totalCopied = 0;
    let totalSkipped = 0;

    for (const { source, target } of datePairs) {
      const schedules = await DoctorSchedule.find({ date: source }).lean();

      for (const schedule of schedules) {
        try {
          const { _id, createdAt, updatedAt, __v, ...rest } = schedule as any;
          await DoctorSchedule.create({ ...rest, date: target });
          totalCopied++;
        } catch (err: any) {
          if (err.code === 11000) {
            // Trùng lịch → bỏ qua, không dừng toàn bộ
            totalSkipped++;
          } else {
            // Lỗi không mong muốn → ném ra ngoài
            throw err;
          }
        }
      }
    }

    res.status(201).json({
      message: `Sao chép hoàn tất! Đã tạo ${totalCopied} ca trực, bỏ qua ${totalSkipped} ca bị trùng.`,
      copied: totalCopied,
      skipped: totalSkipped,
    });

  } catch (error: any) {
    res.status(500).json({ message: `Lỗi khi sao chép lịch: ${error.message}` });
  }
};