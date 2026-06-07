import express from "express";
import {
  getSalariesByMonth,
  generateMonthlySalaries,
  updateSalary,
  markSalaryPaid,
  getSalarySummary,
} from "../controllers/salary_controller";
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.get("/", verifyToken, getSalariesByMonth);
router.get("/summary", verifyToken, getSalarySummary);
router.post("/generate", verifyToken, generateMonthlySalaries);
router.put("/:id", verifyToken, updateSalary);
router.patch("/:id/pay", verifyToken, markSalaryPaid);

export default router;
