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

const router = express.Router();

router.get('/stats', getAdminStats as any);
router.get('/chart-data', getChartData as any);
router.get('/users', getUsers as any);
router.post('/users', createBaseAccount as any);
router.patch('/users/:id/status', toggleUserStatus as any);
router.get('/doctors/pending', getPendingDoctors as any);
router.get('/doctors/rejected', getRejectedDoctors as any);
router.post('/doctors/approve', approveDoctor as any);
router.post('/doctors/reject', rejectDoctor as any);
router.get('/doctors/active', getActiveDoctors as any);
router.patch('/doctors/:id/fee', updateDoctorFee as any);

export default router;
