import express from "express";
import { getAllAds, getActiveAds, createAd, updateAd, deleteAd, trackAdClick } from "../controllers/advertisement_controller";
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.get("/", verifyToken, getAllAds);
router.get("/active", getActiveAds);
router.post("/", verifyToken, createAd);
router.put("/:id", verifyToken, updateAd);
router.delete("/:id", verifyToken, deleteAd);
router.post("/:id/click", trackAdClick);

export default router;
