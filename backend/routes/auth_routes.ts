import { RequestHandler, Router } from 'express';
import multer from 'multer';

import { register,registerByAdmin,login,verifyOtp,logout,  } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../middleware/auth';
import{updateUserInfor,getUserInfor,changePassword, updateProfile,  getProfile,
    changePassWord,} from '../controllers/user_controller';
import { addDepartments, getDepartments,updateDepartment,
    deleteDepartment, } from '../controllers/departments_cotroller';
import {getUser, changeUserRole,toggleUserActive} from '../controllers/security_controller';

import {createMedicalRecord,updateMedicalRecord, getMedicalRecord} from '../controllers/medicalRecordInfor_controller';
import {addMedicalRecord,listMedicalRecords,getMedicalRecordDetail,searchMedicalRecords,} from "../controllers/medicalRecordController";
import upload from "../middleware/upload";
import { predictDiabetes, predictResourcePPO } from '../controllers/predictController';


const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post("/logout", logout);
router.put("/change-password", changePassword);
router.post('/register-by-admin', verifyToken, isAdmin, registerByAdmin);
router.put("/api-changePassWord", verifyToken,changePassWord);
router.post("/verify-otp", verifyOtp);


// Routes of get Users
router.get("/api_accountList",verifyToken,getUser);
router.put("/api_changeUserRole/:id",verifyToken,changeUserRole);
router.put("/api_updateStatus/:id",verifyToken, toggleUserActive);
router.put("/api_updateUserInfor/:id", verifyToken,updateUserInfor);
router.get("/api_getUserInfor/:id", verifyToken,getUserInfor);
router.patch('/update_profile', verifyToken, updateProfile);
router.get('/get_profile', verifyToken, getProfile);

// routers of Departments
router.post('/api_addDepartment',verifyToken, addDepartments);
router.get("/api_departmentList",verifyToken, getDepartments);                
router.put("/api_updatDepartment/:id",verifyToken, updateDepartment);           
router.delete("/api_deleteDepartment/:id",verifyToken, deleteDepartment);



 //AI router python
 router.post("/api_predict",verifyToken, predictDiabetes);
 router.post("/ai/predictPPO", verifyToken, predictResourcePPO);


 // medical record infor
  router.post("/api_addMedicalRecord", verifyToken,createMedicalRecord);
  router.put("/api_updateMedicalRecord/:id", verifyToken,updateMedicalRecord);
  router.get("/api_getMedicalRecord",verifyToken, getMedicalRecord);
  // medical record with block chain 
  router.post("/api/medicalrecord-blockchain", upload.array("attachments", 10),addMedicalRecord);
  router.get("/api/medical-records/:id",verifyToken, getMedicalRecordDetail);
  router.get("/api/list-medical-records", verifyToken,listMedicalRecords);
  router.get("/api/medical-records-search",verifyToken, searchMedicalRecords);
 // router.get("/api/medical-records/:id/verify",verifyToken,verifyMedicalRecord);
  
export default router;
