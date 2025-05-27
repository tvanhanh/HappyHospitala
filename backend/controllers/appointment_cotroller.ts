import { Request, Response } from "express";
import Appointment,{IAppointment} from "../models/Appointment";
import Department,{IDepartment} from"../models/Departments";
import Doctor,{IDoctor} from "../models/Doctor";
import axios from 'axios';


export const addAppointments = async (req: Request, res: Response) => {
  
  try {
    const { patientName, phone, reason, date, time,departmentName,doctorName,  } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);

    // const department = await Department.findById(departmentId);
    // const doctor = await Doctor.findById(doctorId);
//     if (!department || !doctor) {
//    res.status(404).json({ message: "Không tìm thấy thông tin khoa hoặc bác sĩ" });
//    return;
// }
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
      departmentName: departmentName,
      doctorName: doctorName,
      email,
    });

    await newAppointment.save();
    console.log('Dữ liệu gửi tới webhook:', {
      patientName,
      email,
      departmentName,
      doctorName,
      date,
      time,
    });

    // await axios.post('http://localhost:5678/webhook-test/api_n8n/appointments', {
    //   patientName,
    //   departmentName,
    //   doctorName,
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
    const appointment = await Appointment.find()
    const formattedAppointment = await Promise.all(
      appointment.map(async (item: IAppointment) => {
    
        return {
          _id: item._id.toString(),
          patientName: item.patientName || 'Không rõ tên',
          phone: item.phone || 'không có',
          reason: item.reason || 'không có',
          date: item.date || 'không có',
          time: item.time || 'không có',
          doctorName: item.doctorName || 'không rõ',
          departmentName: item.departmentName || 'Không rõ',
          status: item.status || 'không có',
          email: item.email || 'không có', // 👈 đây là nơi email bị mất nếu bị đè
          createdAt: item.createdAt || 'không có',
        };
      })
    );
    
    res.status(200).json(formattedAppointment);
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
export const updateStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // Kiểm tra xem lịch hẹn có tồn tại không
    const appointment = await Appointment.findById(id);
    if (!appointment) {
       res.status(404).json({ message: 'Không tìm thấy lịch hẹn' });
       return;
    }

    // Cập nhật trạng thái
    appointment.status = status;
    await appointment.save();

    res.status(200).json({ message: 'Cập nhật trạng thái thành công', appointment });
  } catch (error) {
    console.error("Lỗi khi cập nhật trạng thái:", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

