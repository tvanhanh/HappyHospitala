import express, { RequestHandler } from 'express';
import {
  createRoom,
  getRooms,
  getRoomById,
  updateRoom,
  deleteRoom
} from '../controllers/RoomController';

const router = express.Router();

router.post('/', createRoom);
router.get('/', getRooms);
router.get('/:id', getRoomById as any);
router.put('/:id', updateRoom as any);
router.delete('/:id', deleteRoom as any);

export default router;
