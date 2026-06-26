import express, { RequestHandler } from 'express';
import {
  createService,
  getServices,
  getServiceById,
  updateService,
  deleteService
} from '../controllers/ServiceController';

const router = express.Router();

router.post('/', createService as RequestHandler);
router.get('/', getServices as RequestHandler);
router.get('/:id', getServiceById as RequestHandler);
router.put('/:id', updateService as RequestHandler);
router.delete('/:id', deleteService as RequestHandler);

export default router;
