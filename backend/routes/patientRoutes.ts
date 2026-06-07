import express from 'express';
import { getPatients } from '../controllers/patient_controller';

const router = express.Router();

router.get('/', getPatients);

export default router;
