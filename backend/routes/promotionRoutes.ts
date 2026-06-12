import express from "express";
import {
  getAllPromotions,
  getActivePromotions,
  createPromotion,
  updatePromotion,
  deletePromotion,
  validatePromoCode,
} from "../controllers/promotion_controller";
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.get("/", verifyToken, getAllPromotions);
router.get("/active", getActivePromotions);          // Public — patients see active promos
router.post("/validate", verifyToken, validatePromoCode);
router.post("/", verifyToken, createPromotion);
router.put("/:id", verifyToken, updatePromotion);
router.delete("/:id", verifyToken, deletePromotion);

export default router;
