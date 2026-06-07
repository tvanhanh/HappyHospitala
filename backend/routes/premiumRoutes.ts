import express from "express";
import {
  getAllPackages, createPackage, updatePackage, deletePackage,
  getAllSubscriptions, subscribe, getUserSubscription,
} from "../controllers/premium_controller";
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.get("/packages", getAllPackages);
router.post("/packages", verifyToken, createPackage);
router.put("/packages/:id", verifyToken, updatePackage);
router.delete("/packages/:id", verifyToken, deletePackage);
router.get("/subscriptions", verifyToken, getAllSubscriptions);
router.post("/subscribe", verifyToken, subscribe);
router.get("/user/:userId", verifyToken, getUserSubscription);

export default router;
