import { Request, Response } from "express";
import Appointment from "../models/Appointment";
import axios from 'axios';


export const addAppointments = async (req: Request, res: Response) => {
  
  try {
    const { patientName, phone, reason, date, time } = req.body;
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
      describe: reason,
      date: date,
      time: time,
      email,
    });

    await newAppointment.save();
    console.log('Dữ liệu gửi tới webhook:', {
      patientName,
      email,
      date,
      time,
    });

    await axios.post('http://localhost:5678/webhook-test/api_n8n/appointments', {
      patientName,
      email,
      date,
      time,
    });

     res.status(201).json({ message: "Đặt lịch thành công", appointment: newAppointment });
    return;
  } catch (error) {
    console.error("Lỗi khi tạo lịch hẹn:", error);
     res.status(500).json({ message: "Lỗi máy chủ" });
     return;
  }
};
