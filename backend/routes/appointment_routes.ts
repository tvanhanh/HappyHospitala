import { getAllAppointments, getAppointmentStatusChart } from './../controllers/appointment_controller';
import express from "express";
import {
  addAppointment,
  updateStatus,
  getMyAppointments,
  cancelAppointment,
  getDoctorAppointments,
  getAppointmentsByDate,
  getBookedSlots,
  checkSlotAvailability,
  checkInAppointment,
  submitPreVisitData,
  lockSession,
} from '../controllers/appointment_controller';
import { isAdmin, verifyToken } from "../middleware/auth";


const router = express.Router();
router.post("/add", verifyToken, addAppointment);
router.get("/", verifyToken, getAllAppointments);
router.get("/doctor", verifyToken, getDoctorAppointments);
router.get("/patient", verifyToken, getMyAppointments);
router.get("/date", verifyToken, getAppointmentsByDate);
router.get("/booked-slots", verifyToken, getBookedSlots);
router.get("/check-slot", verifyToken, checkSlotAvailability);   // Pre-submit slot check
router.patch("/:id/check-in", verifyToken, checkInAppointment);  // Receptionist check-in
router.patch("/:id/pre-visit", verifyToken, submitPreVisitData);
router.post("/:id/lock-session", verifyToken, lockSession);
router.patch("/:id/:status", verifyToken, updateStatus);
router.patch("/:id", verifyToken, cancelAppointment);
router.get('/appointment-status', verifyToken, isAdmin, getAppointmentStatusChart);

export default router;
