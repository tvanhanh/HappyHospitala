import { RequestHandler, Router } from 'express';
import { register, createUserByAdmin,login } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../middleware/auth';
import { addDepartments, 
    getDepartments,
    updateDepartment,
    deleteDepartment, } from '../controllers/departments_cotroller';
import {getUser, changeUserRole,toggleUserActive} from '../controllers/security_controller';
import {getDoctors, addDoctors, deleteDoctor, updateDoctor} from '../controllers/doctor_controller';


const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post('/admin/create-user', verifyToken, isAdmin, createUserByAdmin );

// Routes of get Users
router.get("/api_accountList",verifyToken,getUser);
router.put("/api_changeUserRole/:id",verifyToken,changeUserRole);
router.put("/api_updateStatus/:id",verifyToken, toggleUserActive);


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

export default router;
