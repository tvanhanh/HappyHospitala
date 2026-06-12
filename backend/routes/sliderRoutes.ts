import express from 'express';
import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import {
  getAllSliders,
  getActiveSliders,
  createSlider,
  toggleSlider,
  deleteSlider,
} from '../controllers/slider_controller';

const router = express.Router();

// Cấu hình Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dwlikpvh9',
  api_key: process.env.CLOUDINARY_API_KEY || '519632832822765',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'Z7Gv0mI52j8FkQp78Nf_wM-vW4Y', // Assume standard setup or fallback
});

// Cấu hình Multer-Storage-Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    return {
      folder: 'sliders',
      allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
    };
  },
});

const upload = multer({ storage: storage });

// Routes (dành cho Admin và Frontend)
router.get('/', getActiveSliders); // Dành cho Patient trang chủ
router.get('/all', getAllSliders); // Dành cho Admin dashboard

// POST /sliders thay cho POST /admin/sliders như trong code hiện tại của home_provider.dart
router.post('/', (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      console.error('MULTER ERROR:', err);
      return res.status(400).json({ message: 'Lỗi tải ảnh', error: String(err) });
    }
    next();
  });
}, createSlider); 

router.patch('/:id', toggleSlider);
router.delete('/:id', deleteSlider);

export default router;
