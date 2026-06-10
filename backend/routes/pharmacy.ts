import { Router } from 'express';
import { verifyToken } from '../middleware/auth';
import { getAllCategories, createCategory, updateCategory, deleteCategory } from '../controllers/categoryController';
import { addMedicine, listMedicines, updateMedicine, deleteMedicine } from '../controllers/medicineController';

const router = Router();

// Category routes
router.get('/categories', verifyToken, getAllCategories);
router.post('/categories', verifyToken, createCategory);
router.put('/categories/:id', verifyToken, updateCategory);
router.delete('/categories/:id', verifyToken, deleteCategory);

// Medicine routes
router.post('/medicines', verifyToken, addMedicine);
router.get('/medicines', verifyToken, listMedicines);
router.put('/medicines/:id', verifyToken, updateMedicine);
router.delete('/medicines/:id', verifyToken, deleteMedicine);

export default router;
