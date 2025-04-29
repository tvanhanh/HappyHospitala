import { RequestHandler, Router } from 'express';
import {addAppointments} from "../controllers/appointment_cotroller";
import { verifyToken } from '../middleware/auth';


const router = Router();

router.post('/addAppointment',verifyToken, addAppointments);


export default router;
