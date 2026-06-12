import express from "express";
import {
  getRevenueReport,
  getAppointmentStats,
  getPatientStats,
  getDoctorPerformance,
  getDashboardOverview,
} from "../controllers/report_controller";
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.get("/overview", verifyToken, getDashboardOverview);
router.get("/revenue", verifyToken, getRevenueReport);
router.get("/appointments", verifyToken, getAppointmentStats);
router.get("/patients", verifyToken, getPatientStats);
router.get("/doctors", verifyToken, getDoctorPerformance);

export default router;
