import { Request, Response } from 'express';
import User from '../models/User';
import Patient from '../models/Patient';

export const getPatients = async (req: Request, res: Response) => {
  try {
    const { search } = req.query;

    // Chỉ lấy những user có role là patient và chưa bị xóa mềm
    let query: any = { 
      role: 'patient',
      isDeleted: false 
    };
    
    // Nếu có từ khóa tìm kiếm
    if (search && typeof search === 'string') {
      const searchRegex = new RegExp(search, 'i'); // 'i' để không phân biệt hoa thường
      
      // Tìm kiếm trên các trường đã được "phẳng hóa"
      query.$or = [
        { fullName: searchRegex },
        { phoneNumber: searchRegex },
        { cccd: searchRegex },
        { email: searchRegex }
      ];
    }

    // Không cần populate nữa, lấy thẳng dữ liệu
    const patients = await User.find(query)
      .select('-password') // Bỏ đi trường password cho bảo mật
      .sort({ createdAt: -1 });

    // Ghép thêm thông tin BHYT (healthInsuranceCode) từ collection Patient
    const patientsWithInsurance = await Promise.all(
      patients.map(async (user) => {
        const patientDoc = await Patient.findOne({ userId: user._id });
        return {
          ...user.toObject(),
          healthInsurance: patientDoc?.healthInsuranceCode || "",
        };
      })
    );

    res.status(200).json(patientsWithInsurance);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};