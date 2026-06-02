import { getAllAppointments } from './../controllers/appointment_controller';
import express from "express";
import {
  addAppointment,
  updateStatus,
  getMyAppointments,
  cancelAppointment,
  getDoctorAppointments,
} from '../controllers/appointment_controller';
import { verifyToken } from "../middleware/auth";

const router = express.Router();


router.post("/add", verifyToken, addAppointment);

// GET ALL
router.get("/", verifyToken, getAllAppointments);

// GET BY DOCTOR
router.get("/doctor", verifyToken, getDoctorAppointments);

// GET BY PATIENT
router.get("/patient", verifyToken, getMyAppointments);

// UPDATE STATUS
router.patch("/:id/:status", verifyToken, updateStatus);

// DELETE
router.patch("/:id", verifyToken, cancelAppointment);

export default router;