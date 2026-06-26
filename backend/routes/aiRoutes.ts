import express from 'express';
import { triage, getHistory, clearHistory, getHandoffSessions, initiateHandoffChat } from '../controllers/aiController';
import { verifyToken } from '../middleware/auth';

const router = express.Router();

// Tất cả các tuyến đường AI Triage đều yêu cầu người dùng xác thực
router.post('/triage', verifyToken as express.RequestHandler, triage as express.RequestHandler);
router.get('/history', verifyToken as express.RequestHandler, getHistory as express.RequestHandler);
router.delete('/history', verifyToken as express.RequestHandler, clearHistory as express.RequestHandler);
router.get('/handoffs', verifyToken as express.RequestHandler, getHandoffSessions as express.RequestHandler);
router.post('/initiate-chat', verifyToken as express.RequestHandler, initiateHandoffChat as express.RequestHandler);

export default router;
