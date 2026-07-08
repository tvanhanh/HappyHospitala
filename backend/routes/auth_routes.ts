import { RequestHandler, Router } from 'express';
import multer from 'multer';

import { register,registerByAdmin,login,verifyOtp,logout, sendOtpRegister, googleLogin, sendOtpForgot, resetPassword } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../middleware/auth';
import{updateUserInfor,getUserInfor,changePassword, updateProfile,  getProfile,
    changePassWord,} from '../controllers/user_controller';
import { addDepartments, getDepartments,updateDepartment,
    deleteDepartment, } from '../controllers/departments_cotroller';
import {getUser, changeUserRole,toggleUserActive} from '../controllers/security_controller';

import {createMedicalRecord,updateMedicalRecord, getMedicalRecord} from '../controllers/medicalRecordInfor_controller';
import {addMedicalRecord,listMedicalRecords,getMedicalRecordDetail,searchMedicalRecords,getDoctorAccessRequestsHistory,verifyMedicalRecordIntegrity, requestAccess,approveAccessRequest,viewMedicalRecordPdf,respondToAccessRequest,getMedicalRecordDetailForDoctor,getMedicalRecordById} from "../controllers/medicalRecordController";
import upload from "../middleware/upload";
import { predictDiabetes, predictResourcePPO, predictSkin } from '../controllers/predictController';
import { getAllMedicineCategories, createMedicineCategory } from "../controllers/categoryOfMedicineController";
import { createSupplier ,deleteSupplier,updateSupplier,getAllSuppliers} from '../controllers/supplier_controller';
import { getAllMedicines, createMedicine, deleteMedicine,updateMedicine, } from '../controllers/medicineController';
import {createPrescription,getPrescriptions,  getPrescriptionById,updatePrescriptionStatus,getPrescriptionByAppointment} from '../controllers/prescriptionController';
import { createImportMedicne, getImportRecords,approveImportBill } from '../controllers/importMedicneController';
import { createBill, getBills, getBillById } from '../controllers/billController';
import {getSentRequests,getReceivedRequests} from '../controllers/request_controller';
import { getMessages,createMessage,getChatRooms,getPatientMessages,deletePatientChat,updateMessage,deleteSingleMessage } from '../controllers/messageController';
import { getAllInventories, getInventoryById, reduceStockQuantity,checkMedicinesStock } from '../controllers/inventoryController';

import { controllers } from 'chart.js';



const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post("/logout", logout);
router.put("/change-password", changePassword);
router.post('/register-by-admin', verifyToken, isAdmin, registerByAdmin);
router.put("/api-changePassWord", verifyToken,changePassWord);
router.post("/verify-otp", verifyOtp);
router.post("/send-otp-register", sendOtpRegister);
router.post("/google-login", googleLogin);
router.post("/send-otp-forgot", sendOtpForgot);
router.post("/reset-password", resetPassword);


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
  router.post("/api/medical-records", verifyToken, addMedicalRecord);
  router.get("/api/medical-records/:id",verifyToken, getMedicalRecordDetail);
  router.get("/api/list-medical-records", verifyToken,listMedicalRecords);
  router.get("/api/medical-records-search",verifyToken, searchMedicalRecords);
 // router.get("/api/medical-records/:id/verify",verifyToken,verifyMedicalRecord);
 router.post("/verify-blockchain", verifyToken,verifyMedicalRecordIntegrity);
 router.post("/request",verifyToken, requestAccess);
 router.put("/respond",verifyToken, respondToAccessRequest);
 router.get("/record-detail",verifyToken, getMedicalRecordDetailForDoctor);
router.get("/download-pdf/:recordId", verifyToken, viewMedicalRecordPdf);
router.get("/requests/doctor-history", verifyToken, getDoctorAccessRequestsHistory);
router.get("/sent-history", verifyToken,getSentRequests);
router.get('/received-requests', verifyToken, getReceivedRequests);
router.post("/approve", verifyToken, approveAccessRequest);
router.get('/getmedicalrecordbypatientid/:id', verifyToken, getMedicalRecordById);
 // category of medicine
 router.get("/get_category",verifyToken, getAllMedicineCategories);
 router.post("/create_category", verifyToken, createMedicineCategory);
 // medicine
 router.post("/create_medicine", verifyToken, createMedicine);
 router.get("/get_medicines", verifyToken, getAllMedicines);
 router.delete("/delete_medicine/:id", verifyToken, deleteMedicine);
 router.put("/update_medicine/:id", verifyToken, updateMedicine);
 // prescrition
 router.post("/create_prescription", verifyToken, createPrescription);
 router.get('/get_prescriptions',verifyToken, getPrescriptions);
 router.get('/get_prescriptionsDetail/:id',verifyToken, getPrescriptionById);
 router.get('/get_prescription_by_appointment/:id',verifyToken, getPrescriptionByAppointment);
 router.put('/update_status_prescriptions/:id/status',verifyToken, updatePrescriptionStatus);
 // supplier 
router.post('/create_supplier',verifyToken,createSupplier);
router.get('/get_suppliers', verifyToken,getAllSuppliers);
// importMedicine
 router.post("/create_importmedicine", verifyToken, createImportMedicne);
 router.get('/get_importmedicine',verifyToken, getImportRecords);
 router.put('/update_status_import',verifyToken, approveImportBill);
// inventories
router.get('/get_inventories',verifyToken, getAllInventories);
router.get('/get_inventoriesbyId/:id',verifyToken, getInventoryById);
router.post('/reduce',verifyToken, reduceStockQuantity);
router.post('/check-stock' ,verifyToken, checkMedicinesStock);
 //bill
 router.post("/create_bill", verifyToken, createBill);
 router.get('/get_bills',verifyToken, getBills);
 router.get('/get_bill/:id',verifyToken, getBillById);
 // messenger
 router.get('/get_messages',verifyToken, getMessages);
 // Gửi tin nhắn (Hỗ trợ text đơn thuần hoặc đính kèm File nhận trực tiếp vào RAM tối đa 10MB)
 router.post('/messages', upload.single('file'),verifyToken, createMessage);
 router.get('/get_chat_rooms', verifyToken, getChatRooms);
 router.get('/patient/messages', verifyToken, getPatientMessages);
 router.delete('/patient/chat', verifyToken, deletePatientChat);
 router.put('/messages/update', verifyToken, updateMessage);
 router.delete('/messages/delete/:messageId', verifyToken, deleteSingleMessage);
 router.post("/api_predict_skin", upload.single('file'), verifyToken, predictSkin);

 // Fallback cho chat_screen.dart (để tránh 404 khi gọi trực tiếp GET /messages/:roomId)
 router.get('/messages/:roomId', verifyToken, async (req: any, res: any) => {
   req.query.roomId = req.params.roomId;
   return getMessages(req, res);
 });

// Endpoint truyền ID tham số: /api/suppliers/:id
router.put('/update_supplier/:id', verifyToken, updateSupplier);
router.delete('/delete_supplier/:id', verifyToken, deleteSupplier);
export default router;
