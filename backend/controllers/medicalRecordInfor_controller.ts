import { Request, Response } from 'express';
import DiabetesRecord, { IDiabetesRecord } from '../models/medicl_record_infor';;

// Thêm mới bệnh án
export const createMedicalRecord = async (req: Request, res: Response) => {
  try {
    const { patientId, doctorId, patientName,email, examinationDate, examinationTime,doctorName,departmentName, gender, age, urea, creatinine, hba1c, cholesterol,triglycerides, hdl, ldl, vldl, bmi, status } = req.body;
    console.log("Dữ liệu nhận từ frontend:", req.body);

    const newRecord = new DiabetesRecord ({
        patientId,
        doctorId,
        patientName,
        email,
        examinationDate,
        examinationTime,
        doctorName,
        departmentName,
        gender,
        age,
        urea,
        creatinine,
        hba1c,
        cholesterol,
        triglycerides,
        hdl,
        ldl,
        vldl,
        bmi,
        status,

    });
     await newRecord.save();
    res.status(201).json({ message: "Thêm thành công", DiabetesRecord: newRecord });
  } catch (error) {
    console.error("Lỗi khi tạo bệnh án:", error);
    res.status(500).json({ message: 'Lỗi khi tạo bệnh án', error });
  }
};

export const getMedicalRecord = async (req: Request, res: Response) => {
  try {
    if (!req.user || !req.user.email) {
       res.status(401).json({ message: 'Người dùng chưa đăng nhập' });
       return;
    }

    const role = req.user.role;
    // 1. Lấy patientId truyền từ Flutter lên (nếu có) thông qua Query Parameters (?patientId=...)
    const { patientId } = req.query; 

    let queryCondition: any = {};

    if (role === 'admin' || role === 'doctor') {
      // Nếu có truyền bệnh nhân cụ thể từ trang trước sang, lọc theo đúng patientId đó
      if (patientId) {
        queryCondition = { patientId: patientId };
      } else {
        queryCondition = {}; // Ngược lại thì lấy hết
      }
    } else {
      // Nếu là role bệnh nhân, chỉ cho phép xem hồ sơ của chính mình qua email đăng nhập
      queryCondition = { email: req.user.email };
    }

    
    // 2. Truy vấn dữ liệu (Hãy đảm bảo DiabetesRecord Schema đã có các trường blockchain)
    const medicalRecords = await DiabetesRecord.find(queryCondition)
      .populate('patientId')
      .populate({
        path: 'doctorId',
        populate: { path: 'userId' }
      });
  
    
    res.status(200).json(medicalRecords);
  } catch (error) {
    console.error("Lỗi khi lấy dữ liệu bệnh án", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};

// Cập nhật bệnh án theo ID
export const updateMedicalRecord = async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const updatedRecord = await DiabetesRecord.findByIdAndUpdate(id, req.body, { new: true });
    if (!updatedRecord) {
       res.status(404).json({ message: 'Không tìm thấy bệnh án' });
       return;
    }
    res.status(200).json(updatedRecord);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi cập nhật bệnh án', error });
  }
};
