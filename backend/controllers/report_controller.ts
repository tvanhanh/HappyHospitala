import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import Doctor from "../models/Doctor";
import User from "../models/User";

/**
 * Report Controller — Báo cáo & thống kê
 * [BMC] View Reports & Statistics theo Use Case Admin Module
 */

// ── REVENUE REPORT ────────────────────────────────────────────────────────
export const getRevenueReport = async (req: Request, res: Response): Promise<any> => {
  try {
    const { period = "month", year, month } = req.query;
    const now = new Date();
    const currentYear = Number(year) || now.getFullYear();
    const currentMonth = Number(month) || now.getMonth() + 1;

    let matchStage: any = { status: "completed" };

    if (period === "day") {
      // Last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      matchStage.date = { $gte: thirtyDaysAgo.toISOString().split("T")[0] };
    } else if (period === "month") {
      // This month
      const monthStr = String(currentMonth).padStart(2, "0");
      matchStage.date = { $regex: `^${currentYear}-${monthStr}` };
    } else if (period === "year") {
      matchStage.date = { $regex: `^${currentYear}` };
    }

    // Aggregate revenue by date
    const revenueByDate = await Appointment.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: "$date",
          totalRevenue: { $sum: "$finalFee" },
          count: { $sum: 1 },
          cashRevenue: { $sum: { $cond: [{ $eq: ["$paymentMethod", "cash"] }, "$finalFee", 0] } },
          insuranceRevenue: { $sum: { $cond: [{ $eq: ["$paymentMethod", "insurance"] }, "$finalFee", 0] } },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Total stats
    const totalStats = await Appointment.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: "$finalFee" },
          totalAppointments: { $sum: 1 },
          avgFee: { $avg: "$finalFee" },
          cashRevenue: { $sum: { $cond: [{ $eq: ["$paymentMethod", "cash"] }, "$finalFee", 0] } },
          insuranceRevenue: { $sum: { $cond: [{ $eq: ["$paymentMethod", "insurance"] }, "$finalFee", 0] } },
        },
      },
    ]);

    // Top doctors by revenue
    const topDoctors = await Appointment.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: "$doctor",
          totalRevenue: { $sum: "$finalFee" },
          count: { $sum: 1 },
        },
      },
      { $sort: { totalRevenue: -1 } },
      { $limit: 5 },
      {
        $lookup: {
          from: "doctors",
          localField: "_id",
          foreignField: "_id",
          as: "doctorInfo",
        },
      },
      { $unwind: { path: "$doctorInfo", preserveNullAndEmptyArrays: true } },
    ]);

    res.json({
      success: true,
      data: {
        revenueByDate,
        summary: totalStats[0] || { totalRevenue: 0, totalAppointments: 0, avgFee: 0 },
        topDoctors,
        period,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi báo cáo doanh thu", error: err });
  }
};

// ── APPOINTMENT STATS ─────────────────────────────────────────────────────
export const getAppointmentStats = async (req: Request, res: Response): Promise<any> => {
  try {
    const { month, year } = req.query;
    const now = new Date();
    const currentYear = Number(year) || now.getFullYear();
    const currentMonth = Number(month) || now.getMonth() + 1;
    const monthStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}`;

    // By status
    const byStatus = await Appointment.aggregate([
      { $match: { date: { $regex: `^${monthStr}` } } },
      { $group: { _id: "$status", count: { $sum: 1 } } },
    ]);

    // By specialty (via doctor lookup)
    const bySpecialty = await Appointment.aggregate([
      { $match: { date: { $regex: `^${monthStr}` } } },
      {
        $lookup: {
          from: "doctors",
          localField: "doctor",
          foreignField: "_id",
          as: "doctorInfo",
        },
      },
      { $unwind: { path: "$doctorInfo", preserveNullAndEmptyArrays: true } },
      {
        $lookup: {
          from: "specialties",
          localField: "doctorInfo.specialtyId",
          foreignField: "_id",
          as: "specialtyInfo",
        },
      },
      { $unwind: { path: "$specialtyInfo", preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: "$specialtyInfo.name",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ]);

    // Daily trend for the month
    const dailyTrend = await Appointment.aggregate([
      { $match: { date: { $regex: `^${monthStr}` } } },
      { $group: { _id: "$date", count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);

    const totalAppointments = await Appointment.countDocuments({
      date: { $regex: `^${monthStr}` },
    });
    const completed = await Appointment.countDocuments({
      date: { $regex: `^${monthStr}` },
      status: "completed",
    });
    const cancelled = await Appointment.countDocuments({
      date: { $regex: `^${monthStr}` },
      status: "cancelled",
    });

    res.json({
      success: true,
      data: {
        byStatus,
        bySpecialty,
        dailyTrend,
        summary: {
          total: totalAppointments,
          completed,
          cancelled,
          completionRate: totalAppointments > 0 ? Math.round((completed / totalAppointments) * 100) : 0,
        },
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi thống kê lịch hẹn", error: err });
  }
};

// ── PATIENT STATS ─────────────────────────────────────────────────────────
export const getPatientStats = async (req: Request, res: Response): Promise<any> => {
  try {
    const totalPatients = await User.countDocuments({ role: "patient", isDeleted: false });
    const newThisMonth = await User.countDocuments({
      role: "patient",
      isDeleted: false,
      createdAt: {
        $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
      },
    });

    // Patients by blood type
    const byBloodType = await User.aggregate([
      { $match: { role: "patient", "profile.bloodType": { $exists: true, $ne: "" } } },
      { $group: { _id: "$profile.bloodType", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    res.json({
      success: true,
      data: { totalPatients, newThisMonth, byBloodType },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi thống kê bệnh nhân" });
  }
};

// ── DOCTOR PERFORMANCE ────────────────────────────────────────────────────
export const getDoctorPerformance = async (req: Request, res: Response): Promise<any> => {
  try {
    const { month, year } = req.query;
    const now = new Date();
    const currentYear = Number(year) || now.getFullYear();
    const currentMonth = Number(month) || now.getMonth() + 1;
    const monthStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}`;

    const performance = await Appointment.aggregate([
      { $match: { date: { $regex: `^${monthStr}` } } },
      {
        $group: {
          _id: "$doctor",
          totalAppointments: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] } },
          cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
          totalRevenue: { $sum: "$finalFee" },
        },
      },
      {
        $lookup: {
          from: "doctors",
          localField: "_id",
          foreignField: "_id",
          as: "doctor",
        },
      },
      { $unwind: { path: "$doctor", preserveNullAndEmptyArrays: true } },
      {
        $lookup: {
          from: "specialties",
          localField: "doctor.specialtyId",
          foreignField: "_id",
          as: "specialty",
        },
      },
      { $unwind: { path: "$specialty", preserveNullAndEmptyArrays: true } },
      { $sort: { completed: -1 } },
    ]);

    res.json({ success: true, data: performance });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi thống kê bác sĩ" });
  }
};

// ── OVERVIEW DASHBOARD ────────────────────────────────────────────────────
export const getDashboardOverview = async (req: Request, res: Response): Promise<any> => {
  try {
    const now = new Date();
    const todayStr = now.toISOString().split("T")[0];
    const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

    const [
      totalDoctors,
      totalPatients,
      totalStaff,
      todayAppointments,
      monthAppointments,
      pendingAppointments,
      monthRevenue,
    ] = await Promise.all([
      Doctor.countDocuments({ isDeleted: false }),
      User.countDocuments({ role: "patient", isDeleted: false }),
      User.countDocuments({ role: { $in: ["receptionist", "cashier", "pharmacy"] }, isDeleted: false }),
      Appointment.countDocuments({ date: todayStr }),
      Appointment.countDocuments({ date: { $regex: `^${monthStr}` } }),
      Appointment.countDocuments({ status: "pending" }),
      Appointment.aggregate([
        { $match: { date: { $regex: `^${monthStr}` }, status: "completed" } },
        { $group: { _id: null, total: { $sum: "$finalFee" } } },
      ]),
    ]);

    res.json({
      success: true,
      data: {
        totalDoctors,
        totalPatients,
        totalStaff,
        todayAppointments,
        monthAppointments,
        pendingAppointments,
        monthRevenue: monthRevenue[0]?.total || 0,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi tổng quan" });
  }
};
