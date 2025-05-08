import { RequestHandler, Router } from 'express';
import {addAppointments, getAppointment,getMonthlyAppointments,updateStatus} from "../controllers/appointment_cotroller";
import { verifyToken } from '../middleware/auth';


const router = Router();

router.post('/addAppointment',verifyToken, addAppointments);
router.get('/monthly',verifyToken,getMonthlyAppointments);
router.get('/getAppoitment',verifyToken,getAppointment);
router.put('/status/:id', verifyToken, updateStatus);



export default router;
