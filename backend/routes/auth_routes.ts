import { RequestHandler, Router } from 'express';
import { register, createUserByAdmin,login } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../middleware/auth';
import { addDepartments, 
    getDepartments,
    updateDepartment,
    deleteDepartment, } from '../controllers/departments_cotroller';
import {getUser, changeUserRole,toggleUserActive} from '../controllers/security_controller';


const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post('/admin/create-user', verifyToken, isAdmin, createUserByAdmin );

// Routes of get Users
router.get("/api_accountList",getUser);
router.put("/api_changeUserRole",changeUserRole);
router.put("/api_updateStatus", toggleUserActive);


// routers of Departments
router.post('/api_addDepartment',verifyToken, addDepartments);
router.get("/api_departmentList",verifyToken, getDepartments);                
router.put("/api_updatDepartment/:id",verifyToken, updateDepartment);           
router.delete("/api_deleteDepartment/:id",verifyToken, deleteDepartment);

export default router;
