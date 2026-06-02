import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import mongoose from "mongoose";

/**
 * ================= CREATE APPOINTMENT =================
 * patient lấy từ JWT
 * doctor lấy từ body
 */
export const addAppointment = async (req: any, res: Response): Promise<void> => {
  try {
    const patientId = req.user.id;

    const {
      doctor,
      patientName,
      phone,
      gender,
      address,
      medicalHistory,
      allergies,
      reason,
      date,
      time,
      imageUrl,
    } = req.body;

    // ================= VALIDATION =================
    if (!doctor || !reason || !date || !time) {
      res.status(400).json({
        success: false,
        message: "Thiếu dữ liệu bắt buộc",
      });
      return;
    }

    // ================= CREATE =================
    const appointment = await Appointment.create({
      patient: patientId,
      doctor,

      patientName,
      phone,
      gender,
      address,
      medicalHistory,
      allergies,

      reason,
      date,
      time,

      imageUrl: imageUrl || "",

      status: "pending",
    });

    res.status(201).json({
      success: true,
      message: "Tạo lịch hẹn thành công",
      data: appointment,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi tạo lịch hẹn",
      error: err,
    });
  }
};

/**
 * ================= GET DOCTOR APPOINTMENTS =================
 */
export const getDoctorAppointments = async (req: any, res: Response): Promise<void> => {
  try {
   const doctorId = new mongoose.Types.ObjectId(req.user.id);
    console.log("req.user.id =", req.user.id);
console.log("type =", typeof req.user.id);
    const appointments = await Appointment.find({
      doctor: doctorId,
    })
      .populate("doctor", "name profile")
      .populate("patient", "name profile")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
      
    });
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};

/**
 * ================= GET ALL (ADMIN) =================
 */
export const getAllAppointments = async (req: any, res: Response): Promise<void> => {
  try {
    const appointments = await Appointment.find()
      .populate("doctor", "name profile")
      .populate("patient", "name profile")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
      
    });
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};
export const getMyAppointments = async (req: any, res: Response): Promise<void> => {
  try {
   const patientId = new mongoose.Types.ObjectId(req.user.id);
    console.log("req.user.id =", req.user.id);
console.log("type =", typeof req.user.id);
    const appointments = await Appointment.find({
      patient: patientId,
    })
      .populate("doctor", "name profile")
      .populate("patient", "name profile")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: appointments,
      
    });
    console.log("APPOINTMENTS:", JSON.stringify(appointments, null, 2));
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Lỗi lấy lịch bệnh nhân",
      error: err,
    });
  }
};
/**
 * ================= UPDATE STATUS =================
 */
export const updateStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const updated = await Appointment.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    );

    res.json({
      success: true,
      message: "Update status success",
      data: updated,
    });
    console.log("UPDATE STATUS HIT");
console.log(req.params);
console.log(req.body);
  } catch (err) {
    res.status(500).json({ message: "Error" });
  }
};

/**
 * ================= DELETE APPOINTMENT =================
 */
export const cancelAppointment = async (req: Request, res: Response) => {
  try {
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      { status: "cancelled" },
      { new: true }
    );

    res.json({
      success: true,
      data: appointment,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Huỷ lịch thất bại",
    });
  }
};