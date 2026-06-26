import express from 'express';
import { 
  assignDoctorSchedule, 
  getSchedulesByDate, 
  updateSchedule, 
  deleteSchedule,
  copySchedule,
  getDoctorSchedules,
} from '../controllers/scheduleController';

const router = express.Router();

// Lấy danh sách lịch trực (theo ngày)
router.get('/', getSchedulesByDate);

// Lấy danh sách lịch trực của một bác sĩ
router.get('/doctor/:doctorId', getDoctorSchedules);

// Phân công lịch trực mới
router.post('/', assignDoctorSchedule);

// Sao chép lịch trực (PHẢI đặt TRƯỚC route /:id để tránh conflict)
router.post('/copy', (req, res, next) => { copySchedule(req, res).catch(next); });

// Cập nhật lịch trực (nhận id từ URL)
router.put('/:id', updateSchedule);

// Xóa lịch trực (nhận id từ URL)
router.delete('/:id', deleteSchedule);

export default router;