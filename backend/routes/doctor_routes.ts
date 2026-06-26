import { Router } from 'express';

import {getDoctors, addDoctors, updateDoctorProfile, getDoctorById, getFeaturedDoctors, getDoctorsByDepartment} from '../controllers/doctor_controller';
import { getOwnDoctorProfile, updateDoctorProfileAndSubmit } from '../controllers/doctor_approval_controller';

import { verifyToken } from '../middleware/auth';
const router = Router();

router.get("/profile", verifyToken, getOwnDoctorProfile);
router.put("/profile", verifyToken, updateDoctorProfileAndSubmit);
router.get("/api_doctorList", verifyToken, getDoctors);
router.post("/api_addDoctor",verifyToken,addDoctors);
router.patch("/:id/profile", verifyToken, updateDoctorProfile);
router.get("/:id/api_doctor_detail", verifyToken, getDoctorById);
router.get("/featured", getFeaturedDoctors);

router.get("/api_doctors_by_department/:specialtyId",verifyToken,getDoctorsByDepartment);

//  router.put("/api_updateDoctor/:id", verifyToken,updateDoctor );
//  router.delete("/api_deleteDoctor/:id", verifyToken, deleteDoctor);
export default router;