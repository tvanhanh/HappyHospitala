import { RequestHandler, Router } from 'express';
import {addAppointments, getAppointment} from "../controllers/appointment_cotroller";
import { verifyToken } from '../middleware/auth';


const router = Router();

router.post('/addAppointment',verifyToken, addAppointments);
router.get('/monthly',verifyToken,getAppointment);


export default router;
