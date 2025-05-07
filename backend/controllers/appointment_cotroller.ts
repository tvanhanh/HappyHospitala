import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import axios from 'axios';


export const addAppointments = async (req: Request, res: Response) => {
  
  try {
    const { patientName, phone, reason, date, time,departmentName,doctorId, } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);

    if (!req.user || !req.user.email){
         res.status(401).json({ message: 'User not authenticated' });
         return;
    }
    

    const email = req.user.email; // 👈 Lấy email từ token
   

    if (!email) {
       res.status(401).json({ message: "Không tìm thấy email người dùng" });
       return;
    }

    const newAppointment = new Appointment({
      patientName,
      phone,
      reason,
      date: date,
      time: time,
      departmentName,
      doctorId,
      email,
    });

    await newAppointment.save();
    console.log('Dữ liệu gửi tới webhook:', {
      patientName,
      email,
      date,
      time,
    });

    // await axios.post('http://localhost:5678/webhook-test/api_n8n/appointments', {
    //   patientName,
    //   email,
    //   date,
    //   time,
    // });

     res.status(201).json({ message: "Đặt lịch thành công", appointment: newAppointment });
    return;
  } catch (error) {
    console.error("Lỗi khi tạo lịch hẹn:", error);
     res.status(500).json({ message: "Lỗi máy chủ" });
     return;
  }
};
export const getAppointment = async (req: Request, res: Response) => {
  try {
    const appointment = await Appointment.find();
    res.status(200).json(appointment);
  } catch (error) {
    console.error("Lỗi khi lấy ", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

export const getMonthlyAppointments = async (req: Request, res: Response) => {
  try {
    const appointments = await Appointment.aggregate([
      // Nhóm theo năm và tháng dựa trên trường date
      {
        $addFields: {
          dateObj: { $dateFromString: { dateString: "$date" } }, // Chuyển date từ string sang Date
        },
      },
      {
        $group: {
          _id: {
            year: { $year: "$dateObj" },
            month: { $month: "$dateObj" },
          },
          totalAppointments: { $sum: 1 }, // Đếm tổng số lịch hẹn
          patients: { $addToSet: "$patientName" }, // Tập hợp bệnh nhân duy nhất
          appointments: { $push: "$$ROOT" }, // Lưu toàn bộ thông tin lịch hẹn
        },
      },
      {
        $project: {
          _id: 0,
          year: "$_id.year",
          month: "$_id.month",
          totalAppointments: 1,
          totalPatients: { $size: "$patients" }, // Đếm số bệnh nhân duy nhất
          appointments: 1,
        },
      },
      { $sort: { year: 1, month: 1 } }, // Sắp xếp theo năm và tháng
    ]);

    res.status(200).json(appointments);
  } catch (error) {
    console.error("Lỗi khi lấy thống kê lịch hẹn theo tháng:", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

