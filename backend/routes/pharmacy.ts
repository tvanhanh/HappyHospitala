import { Router } from 'express';
import { verifyToken } from '../middleware/auth';
import { getAllCategories, createCategory, updateCategory, deleteCategory } from '../controllers/categoryController';
import { createMedicine, getAllMedicines, updateMedicine, deleteMedicine } from '../controllers/medicineController';

const router = Router();

// Category routes
router.get('/categories', verifyToken, getAllCategories);
router.post('/categories', verifyToken, createCategory);
router.put('/categories/:id', verifyToken, updateCategory);
router.delete('/categories/:id', verifyToken, deleteCategory);

// Medicine routes
router.post('/medicines', verifyToken, createMedicine);
router.get('/medicines', verifyToken, getAllMedicines);
router.put('/medicines/:id', verifyToken, updateMedicine);
router.delete('/medicines/:id', verifyToken, deleteMedicine);

export default router;
