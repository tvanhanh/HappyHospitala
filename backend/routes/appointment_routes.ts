import { getAllAppointments } from './../controllers/appointment_controller';
import express from "express";
import {
  addAppointment,
  updateStatus,
  getMyAppointments,
  cancelAppointment,
  getDoctorAppointments,
  getAppointmentsByDate,
} from '../controllers/appointment_controller';
import { verifyToken } from "../middleware/auth";

const router = express.Router();
router.post("/add", verifyToken, addAppointment);
router.get("/", verifyToken, getAllAppointments);
router.get("/doctor", verifyToken, getDoctorAppointments);
router.get("/patient", verifyToken, getMyAppointments);
router.get("/date", verifyToken, getAppointmentsByDate);
router.patch("/:id/:status", verifyToken, updateStatus);
router.patch("/:id", verifyToken, cancelAppointment);

export default router;