import { AccessRequest } from '../models/AccessRequest'; // Đường dẫn tới file schema của bạn
import { Types } from 'mongoose';
/**
 * Hàm lấy danh sách yêu cầu truy cập dựa theo patientId
 * @param patientId Chuỗi ID dạng ObjectId của bệnh nhân
 */
export const fetchRequestsByRecordAndDoctor = async (recordId: string, doctorId: string): Promise<any[]> => {
    return await AccessRequest.find({ 
        requestedRecordId: recordId, 
        doctorId: doctorId // Đảm bảo chỉ lấy đúng hồ sơ này của chính bác sĩ này gửi
    })
    .sort({ createdAt: -1 });
};
// Bên trong request.service.ts
export const fetchRequestsByReceiverAndStatus = async (receiverId: string, status: string) => {
    return await AccessRequest.aggregate([
        // 1. Lọc ra các yêu cầu của đúng bệnh nhân này và có trạng thái pending
        {
            $match: {
                patientId: new Types.ObjectId(receiverId),
                status: status
            }
        },
        // 2. [LOOKUP 1]: Nối sang bảng 'users' để lấy họ tên bác sĩ (fullName)
        {
            $lookup: {
                from: 'users', 
                let: { docIdStr: '$doctorId' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $eq: [{ $toString: '$_id' }, '$$docIdStr']
                            }
                        }
                    },
                    { $project: { fullName: 1, _id: 0 } }
                ],
                as: 'userInfo'
            }
        },

        // 3. [LOOKUP 2]: Nối sang bảng 'doctors' để lấy mã phòng ban (specialtyId)
        {
            $lookup: {
                from: 'doctors', // ⚠️ Kiểm tra lại chính xác tên collection bác sĩ của bạn
                let: { docIdStr: '$doctorId' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $eq: [{ $toString: '$userId' }, '$$docIdStr'] 
                            }
                        }
                    },
                    { $project: { specialtyId: 1, _id: 0 } }
                ],
                as: 'doctorProfileInfo'
            }
        },
        // 4. Phẳng hóa dữ liệu specialtyId tạm thời để làm đầu vào cho Lookup tiếp theo
        {
            $addFields: {
                // Ép kiểu specialtyId vừa lấy được từ dạng String/ObjectId trong mảng về thành ObjectId chuẩn
                tempDeptId: {
                    $toObjectId: { $arrayElemAt: ['$doctorProfileInfo.specialtyId', 0] }
                }
            }
        },
        // 5. [LOOKUP 3]: Nối từ tempDeptId sang bảng 'departments' để lấy tên phòng ban thật (departmentName)
        {
            $lookup: {
                from: 'departments', // ⚠️ Thay bằng tên chính xác collection chứa các Phòng Ban của bạn (ví dụ: 'departments', 'clinics'...)
                let: { deptIdObj: '$tempDeptId' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $eq: ['$_id', '$$deptIdObj'] // Vì cả hai đều là ObjectId nên so sánh bằng $eq trực tiếp
                            }
                        }
                    },
                    // 🎯 Giả sử trong bảng phòng ban, trường lưu tên khoa/phòng là 'departmentName' hoặc 'name'
                    { $project: { departmentName:1, _id: 0 } } 
                ],
                as: 'departmentInfo'
            }
        },
        // 6. Map các kết quả tìm được ra các trường phẳng ngoài cùng để Flutter dễ xài
        {
            $addFields: {
                // Lấy ra tên bác sĩ
                doctorName: {
                    $ifNull: [{ $arrayElemAt: ['$userInfo.fullName', 0] }, 'Bác sĩ hệ thống']
                },
                // Lấy ra tên phòng ban (Check cả trường departmentName hoặc trường name phòng hờ)
                doctorDepartment: {
                    $ifNull: [
                        { $arrayElemAt: ['$departmentInfo.departmentName', 0] },
                        { $arrayElemAt: ['$departmentInfo.name', 0] },
                        'Khoa Tổng Quát'
                    ]
                }
            }
        },
        {
            $project: {
                userInfo: 0,
                doctorProfileInfo: 0,
                departmentInfo: 0,
                tempDeptId: 0
            }
        },
        { $sort: { createdAt: -1 } }
    ]);
};