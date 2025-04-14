import { RequestHandler, Router } from 'express';
import { register, createUserByAdmin,login } from '../controllers/auth.controller';
import { verifyToken, isAdmin,  } from '../Middleware/auth';


const router = Router();

router.post('/register',register);
router.post('/login',login);
router.post('/admin/create-user', verifyToken, isAdmin, createUserByAdmin );

export default router;
