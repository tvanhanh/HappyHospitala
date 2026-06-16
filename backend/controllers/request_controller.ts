import { Request, Response } from 'express';
import * as requestService from '../services/request.service';
import { Types } from 'mongoose';
export const getSentRequests = async (req: Request, res: Response): Promise<void> => {
    try {
        console.log("🔍 [Backend GET] Nhận tham số Query từ Flutter:", req.query);
        console.log("🔒 [Backend Auth] Object req.user hiện tại:", req.user);
        console.log("headers nhận được:", req.headers.authorization);
        const requestedRecordId = req.query.recordId as string;
        if (!requestedRecordId) {
            res.status(400).json({
                success: false,
                message: "Thiếu tham số requestedRecordId (Mã hồ sơ) bắt buộc trên Query String!"
            });
            return; 
        }
        const doctorId = req.user?.id;

        if (!doctorId) {
            res.status(401).json({
                success: false,
                message: "Không tìm thấy thông tin xác thực của bác sĩ. Vui lòng đăng nhập lại!"
            });
            return;
        }
        const data = await requestService.fetchRequestsByRecordAndDoctor(requestedRecordId, doctorId);

        res.status(200).json({
            success: true,
            data: data
        });
    } catch (error: any) {
        res.status(500).json({
            success: false,
            message: "Lỗi máy chủ: " + error.message
        });
    }
};
export const getReceivedRequests = async (req: Request, res: Response): Promise<void> => {
    try {
        console.log("📥 [Backend GET] Lấy danh sách yêu cầu ĐÃ NHẬN (Chỉ lấy trạng thái PENDING)");
       
        const patientId = req.user?.id; 

        if (!patientId) {
            res.status(401).json({
                success: false,
                message: "Không tìm thấy thông tin xác thực người dùng. Vui lòng đăng nhập lại!"
            });
            return;
        }

        // 🔥 THAY ĐỔI Ở ĐÂY: Truyền thêm trạng thái 'pending' vào tầng Service để lọc trực tiếp từ DB
        const data = await requestService.fetchRequestsByReceiverAndStatus(patientId, 'pending');
        
        res.status(200).json({
            success: true,
            message: "Lấy danh sách yêu cầu đang chờ phê duyệt thành công!",
            data: data
        });
    } catch (error: any) {
        res.status(500).json({
            success: false,
            message: "Lỗi máy chủ khi lấy yêu cầu nhận: " + error.message
        });
    }
};