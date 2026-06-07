import express from 'express';
import { assignDoctorToRoom, getRoomAssignments, removeAssignment } from '../controllers/room_assignment_controller';

const router = express.Router();

router.post('/', assignDoctorToRoom as any);
router.get('/', getRoomAssignments as any);
router.delete('/:id', removeAssignment as any);

export default router;
