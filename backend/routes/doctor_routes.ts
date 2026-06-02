import { Router } from 'express';
import {getDoctors, addDoctors, updateDoctorProfile, getDoctorById, getFeaturedDoctors,} from '../controllers/doctor_controller';
import { verifyToken } from '../middleware/auth';
const router = Router();

 router.get("/api_doctorList", verifyToken, getDoctors);
 router.post("/api_addDoctor",verifyToken,addDoctors);
 router.patch("/:id/profile", verifyToken, updateDoctorProfile);
 router.get("/:id/api_doctor_detail", verifyToken, getDoctorById);
 router.get("/featured", verifyToken, getFeaturedDoctors);
//  router.put("/api_updateDoctor/:id", verifyToken,updateDoctor );
//  router.delete("/api_deleteDoctor/:id", verifyToken, deleteDoctor);
export default router;