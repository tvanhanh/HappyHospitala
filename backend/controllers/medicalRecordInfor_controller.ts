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

    const email = req.user.email;
    const role = req.user.role;

    let medicalRecords;
    if (role === 'admin' || role === 'doctor') {
      medicalRecords = await DiabetesRecord.find({}).populate('patientId').populate({
        path: 'doctorId',
        populate: { path: 'userId' }
      });
    } else {
      medicalRecords = await DiabetesRecord.find({ email }).populate('patientId').populate({
        path: 'doctorId',
        populate: { path: 'userId' }
      });
    }
    
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
