import { Router } from 'express';
import { 
  createMedicalPost, 
  getApprovedPosts, 
  answerMedicalPost, 
  createComment,
  autoModerateMedicalPost,
  updatePostStatus,
  getAllPostsAdmin,
  getDoctorSpecialtyPosts
} from '../controllers/qaController';
import { verifyToken, isPatient, isDoctor, isAdmin } from '../middleware/auth';

const router = Router();

// 1. Patient Q&A Endpoints (with auto-moderation middleware)
router.post('/posts', verifyToken, isPatient, autoModerateMedicalPost, createMedicalPost);

// 2. Public Q&A Endpoints (open to all roles, no authentication check required for reading approved advice)
router.get('/posts/approved', getApprovedPosts);
router.get('/posts/doctor-specialty', verifyToken, getDoctorSpecialtyPosts);
// 3. Comments/Answers Endpoints
router.post('/posts/:id/comments', verifyToken, createComment);
router.put('/posts/:id/answer', verifyToken, isDoctor, answerMedicalPost); // Legacy answer wrapper for doctors

// 4. Admin Q&A Endpoints
router.patch('/posts/:id/status', verifyToken, isAdmin, updatePostStatus);
router.get('/posts/admin', verifyToken, isAdmin, getAllPostsAdmin);

export default router;
