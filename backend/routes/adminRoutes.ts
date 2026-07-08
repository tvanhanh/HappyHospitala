import express from 'express';
import { 
  getAdminStats, 
  getChartData, 
  createBaseAccount, 
  getUsers,
  toggleUserStatus,
  getPendingDoctors,
  getRejectedDoctors,
  approveDoctor,
  rejectDoctor,
  getActiveDoctors,
  updateDoctorFee
} from '../controllers/AdminController';
import { verifyToken } from '../middleware/auth';

const router = express.Router();

// Thêm verifyToken vào trước các controller
router.get('/stats', verifyToken , getAdminStats as any);
router.get('/chart-data', verifyToken, getChartData as any);
router.get('/users', verifyToken , getUsers as any);
router.post('/users', verifyToken, createBaseAccount as any);
router.patch('/users/:id/status', verifyToken, toggleUserStatus as any);
router.get('/doctors/pending', verifyToken, getPendingDoctors as any);
router.get('/doctors/rejected', verifyToken, getRejectedDoctors as any);
router.post('/doctors/approve', verifyToken, approveDoctor as any);
router.post('/doctors/reject', verifyToken, rejectDoctor as any);
router.get('/doctors/active', verifyToken, getActiveDoctors as any);
router.patch('/doctors/:id/fee', verifyToken, updateDoctorFee as any);

export default router;
