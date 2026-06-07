import express, { RequestHandler } from 'express';
import {
  createSpecialty,
  getSpecialties,
  getSpecialtyById,
  updateSpecialty,
  deleteSpecialty,
  getDoctorsBySpecialty
} from '../controllers/SpecialtyController';

const router = express.Router();

router.post('/', createSpecialty);
router.get('/', getSpecialties);
router.get('/:id', getSpecialtyById as RequestHandler);
router.get('/:specialtyId/doctors', getDoctorsBySpecialty as RequestHandler);
router.put('/:id', updateSpecialty as RequestHandler);
router.delete('/:id', deleteSpecialty as RequestHandler);

export default router;
