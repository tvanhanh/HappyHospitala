import express from 'express';
import { 
  createHiddenDoctor, 
  updateDoctorProfileAndSubmit, 
  reviewDoctorProfile, 
  getActiveDoctorsForPatients,
  getOwnDoctorProfile
} from '../controllers/doctor_approval_controller';
import { verifyToken, isAdmin as verifyAdmin } from '../middleware/auth';

const router = express.Router();

// Role: Admin
router.post('/admin/doctors', verifyToken, verifyAdmin, createHiddenDoctor);
router.put('/admin/doctors/:id/status', verifyToken, verifyAdmin, reviewDoctorProfile);

// Role: Doctor
router.get('/doctor/profile', verifyToken, getOwnDoctorProfile);
router.put('/doctor/profile', verifyToken, updateDoctorProfileAndSubmit);

// Role: Patient / Public
router.get('/patients/doctors', getActiveDoctorsForPatients);

export default router;
