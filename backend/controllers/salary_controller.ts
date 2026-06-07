import { Request, Response } from "express";
import Salary from "../models/Salary";
import Appointment from "../models/Appointment";
import User from "../models/User";
import Doctor from "../models/Doctor";

// ── GET SALARY LIST (by month/year) ────────────────────────────────────────
export const getSalariesByMonth = async (req: Request, res: Response): Promise<any> => {
  try {
    const { month, year } = req.query;
    const filter: any = {};
    if (month) filter.month = Number(month);
    if (year) filter.year = Number(year);

    const salaries = await Salary.find(filter)
      .populate("userId", "name email role profile")
      .populate("paidBy", "name")
      .sort({ createdAt: -1 });

    res.json({ success: true, data: salaries });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi lấy bảng lương" });
  }
};

// ── AUTO-CALCULATE & GENERATE SALARY ────────────────────────────────────────
/**
 * Tự động tính lương cho tất cả bác sĩ/nhân viên trong tháng.
 * Tính consultationBonus từ số lịch hẹn completed trong tháng.
 */
export const generateMonthlySalaries = async (req: any, res: Response): Promise<any> => {
  try {
    const { month, year } = req.body;
    if (!month || !year) {
      return res.status(400).json({ success: false, message: "Thiếu tháng/năm" });
    }

    // Build date range for the month
    const startDate = `${year}-${String(month).padStart(2, "0")}-01`;
    const endDate = `${year}-${String(month).padStart(2, "0")}-31`;

    // Get all doctors
    const doctors = await Doctor.find({ profile_status: 'ACTIVE' }).populate('userId');
    const created: any[] = [];
    const skipped: string[] = [];

    for (const doctor of doctors) {
      // Count completed appointments for this doctor in this month
      const consultationCount = await Appointment.countDocuments({
        doctor: doctor._id,
        date: { $gte: startDate, $lte: endDate },
        status: "completed",
      });

      // Find linked user for this doctor
      const userRef = doctor.userId as any;
      if (!userRef || !userRef._id) {
        skipped.push(userRef?.fullName || 'Unknown');
        continue;
      }

      const baseSalary = 5000000;
      const consultationRate = doctor.consultationFee || 50000;
      const consultationBonus = consultationCount * consultationRate;
      const totalAmount = baseSalary + consultationBonus;

      try {
        const salary = await Salary.findOneAndUpdate(
          { userId: userRef, month, year },
          {
            baseSalary,
            consultationCount,
            consultationRate,
            consultationBonus,
            allowances: 0,
            deductions: 0,
            totalAmount,
            status: "draft",
          },
          { upsert: true, new: true }
        );
        created.push(salary);
      } catch (e) {
        skipped.push(userRef?.fullName || 'Unknown');
      }
    }

    res.json({
      success: true,
      message: `Đã tạo ${created.length} bảng lương tháng ${month}/${year}`,
      data: created,
      skipped,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi tạo bảng lương", error: err });
  }
};

// ── UPDATE SALARY ─────────────────────────────────────────────────────────
export const updateSalary = async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const updated = await Salary.findByIdAndUpdate(id, req.body, { new: true });
    if (!updated) return res.status(404).json({ success: false, message: "Không tìm thấy" });
    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi cập nhật lương" });
  }
};

// ── MARK AS PAID ─────────────────────────────────────────────────────────
export const markSalaryPaid = async (req: any, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const updated = await Salary.findByIdAndUpdate(
      id,
      { status: "paid", paidAt: new Date(), paidBy: req.user?.id },
      { new: true }
    ).populate("userId", "name email");

    if (!updated) return res.status(404).json({ success: false, message: "Không tìm thấy" });
    res.json({ success: true, data: updated, message: "Đã đánh dấu đã trả lương" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi cập nhật" });
  }
};

// ── GET SALARY SUMMARY ────────────────────────────────────────────────────
export const getSalarySummary = async (req: Request, res: Response): Promise<any> => {
  try {
    const { month, year } = req.query;
    const filter: any = {};
    if (month) filter.month = Number(month);
    if (year) filter.year = Number(year);

    const salaries = await Salary.find(filter);
    const total = salaries.reduce((sum, s) => sum + s.totalAmount, 0);
    const paid = salaries.filter((s) => s.status === "paid").length;
    const pending = salaries.filter((s) => s.status !== "paid").length;
    const paidAmount = salaries
      .filter((s) => s.status === "paid")
      .reduce((sum, s) => sum + s.totalAmount, 0);

    res.json({
      success: true,
      data: { total, totalStaff: salaries.length, paid, pending, paidAmount, pendingAmount: total - paidAmount },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Lỗi thống kê lương" });
  }
};
