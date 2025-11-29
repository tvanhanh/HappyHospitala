import { RequestHandler, Router } from 'express';
import { register, createUserByAdmin,login,updateUserInfor,getUserInfor,verifyOtp, changePassWord } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../middleware/auth';
import { addDepartments, 
    getDepartments,
    updateDepartment,
    deleteDepartment, } from '../controllers/departments_cotroller';
import {getUser, changeUserRole,toggleUserActive} from '../controllers/security_controller';
import {getDoctors, addDoctors, deleteDoctor, updateDoctor} from '../controllers/doctor_controller';
import {predictDiabetes} from '../controllers/predictController';
import {createMedicalRecord,updateMedicalRecord, getMedicalRecord} from '../controllers/medicalRecordInfor_controller';
import {addMedicalRecord,getMedicalRecordById } from "../controllers/medicalRecordController";


const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post('/admin/create-user', verifyToken, isAdmin, createUserByAdmin );
router.put("/api-changePassWord", verifyToken,changePassWord);
router.post("/verify-otp", verifyOtp);


// Routes of get Users
router.get("/api_accountList",verifyToken,getUser);
router.put("/api_changeUserRole/:id",verifyToken,changeUserRole);
router.put("/api_updateStatus/:id",verifyToken, toggleUserActive);
router.put("/api_updateUserInfor/:id", verifyToken,updateUserInfor);
router.get("/api_getUserInfor/:id", verifyToken,getUserInfor);


// routers of Departments
router.post('/api_addDepartment',verifyToken, addDepartments);
router.get("/api_departmentList",verifyToken, getDepartments);                
router.put("/api_updatDepartment/:id",verifyToken, updateDepartment);           
router.delete("/api_deleteDepartment/:id",verifyToken, deleteDepartment);

// routers of doctor
 router.get("/api_tocdorList", verifyToken, getDoctors);
 router.post("/api_addDoctor",verifyToken,addDoctors);
 router.put("/api_updateDoctor/:id", verifyToken,updateDoctor );
 router.delete("/api_deleteDoctor/:id", verifyToken, deleteDoctor);

 //AI router python
 router.post("/api_predict",verifyToken, predictDiabetes);

 // medical record infor
  router.post("/api_addMedicalRecord", verifyToken,createMedicalRecord);
  router.put("/api_updateMedicalRecord/:id", verifyToken,updateMedicalRecord);
  router.get("/api_getMedicalRecord",verifyToken, getMedicalRecord);
  // medical record with block chain 
  router.post("/api/medicalrecord-blockchain", addMedicalRecord);
  router.get("/medical-records/:Id",verifyToken,getMedicalRecordById);
  
export default router;
