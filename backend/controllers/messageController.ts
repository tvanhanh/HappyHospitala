import { Request, Response } from 'express';
import { MessageModel } from '../models/Message';
import { ChatRoomModel } from '../models/Room_mes_model';
import User from '../models/User';
import { emitToRole, emitToUser } from '../services/socket.service';

// ─── 1. LẤY LỊCH SỬ CHAT (DÀNH CHO LỄ TÂN CLICK CHỌN PHÒNG) ───────────────────
export const getMessages = async (req: Request, res: Response): Promise<void> => {
  try {
    const { roomId } = req.query; // Đây chính là ID bệnh nhân được truyền từ cột trái lên
    
    if (!roomId) {
      res.status(400).json({ success: false, message: 'Thiếu thông tin roomId (ID bệnh nhân).' });
      return;
    }

    // Lấy lịch sử chat thẳng dựa vào ID bệnh nhân
    const messages = await MessageModel.find({ roomId: roomId.toString() })
      .sort({ createdAt: 1 }) 
      .limit(100);

    res.status(200).json({ 
      success: true, 
      count: messages.length, 
      data: messages 
    });
  } catch (error: any) {
    console.error('💥 Lỗi tại getMessages Controller:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// ─── 2. TẠO TIN NHẮN (ĐỒNG BỘ ROOMID LÀ ID BỆNH NHÂN) ────────────────────────
export const createMessage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { text, roomId } = req.body; 
    const senderId = req.user?.id || req.body.senderId;
    const userRole = req.user?.role; 

    if (!senderId) {
      res.status(401).json({ success: false, message: 'Không tìm thấy thông tin người gửi.' });
      return;
    }

    let textMessage = text ? text.trim() : '';

    // 1. Xử lý file đính kèm
    let imageUrl: string | undefined = undefined;
    if (req.file) {
      const base64Data = req.file.buffer.toString('base64');
      imageUrl = `data:${req.file.mimetype};base64,${base64Data}`;

      if (!textMessage) {
        textMessage = req.file.mimetype.startsWith('image/') ? '📷 Đã gửi một hình ảnh' : `📁 Tệp: ${req.file.originalname}`;
      }
    }

    // 🌟 QUY TẮC: Định vị targetRoomId luôn luôn là ID của Bệnh nhân
    let targetRoomId = roomId;
    const isPatient = userRole !== 'receptionist';

    if (!targetRoomId || isPatient) {
      targetRoomId = senderId.toString(); 
    }

    // 2. Lưu tin nhắn vào bảng Message
    const newMessage = new MessageModel({
      senderId,
      roomId: targetRoomId, // Đồng bộ lưu theo ID bệnh nhân
      text: textMessage,
      imageUrl,
      fileType: req.file?.mimetype ?? null,
    });
    await newMessage.save();

    // 3. Cập nhật hoặc Tự tạo phòng chat ở bảng Room để quản lý danh sách phía cột trái
    await ChatRoomModel.findOneAndUpdate(
      { patientId: targetRoomId },
      {
        patientId: targetRoomId,
        lastMessage: textMessage,
        updatedAt: new Date(),
        isDeletedByPatient: false, // Tin nhắn mới đến -> Tự động kích hoạt lại giao diện bệnh nhân nếu từng ẩn
        status: isPatient ? 'pending' : 'active', 
        $inc: { unreadCount: isPatient ? 1 : 0 } 
      },
      { upsert: true, new: true }
    );

    // Phát sự kiện Socket.io
    if (isPatient) {
      emitToRole('receptionist', 'new_message', newMessage);
    } else {
      emitToUser(targetRoomId.toString(), 'new_message', newMessage);
      // Gửi cho receptionist khác (hoặc chính mình trên tab khác) để cập nhật
      emitToRole('receptionist', 'new_message', newMessage);
    }

    res.status(201).json({ 
      success: true, 
      data: newMessage 
    });
  } catch (error: any) {
    console.error('💥 Lỗi tại createMessage Controller:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// ─── 3. LẤY DANH SÁCH TOÀN BỘ PHÒNG CHAT (DÀNH CHO LỄ TÂN - CỘT TRÁI) ─────────
export const getChatRooms = async (req: Request, res: Response): Promise<void> => {
  try {
    // 1. Lấy danh sách phòng chat từ ChatRoomModel
    const chatRooms = await ChatRoomModel.find().sort({ updatedAt: -1 });

    // 2. Map thông tin phòng chat song song bằng Promise.all
    const formattedRooms = await Promise.all(chatRooms.map(async (room) => {
      let advancedInfo: any = {};

      try {
        // Tìm trực tiếp bệnh nhân trong bảng users bằng patientId
        advancedInfo = await User.findById(room.patientId).lean() || {};
      } catch (err) {
        // Phòng hờ nếu patientId lưu dạng String thay vì ObjectId
        const stringId = room.patientId.toString();
        advancedInfo = await User.findOne({ _id: stringId }).lean() || {};
      }

      // Tính toán tuổi từ ngày sinh (dateOfBirth) nếu có
      let patientAge = "Chưa rõ";
      if (advancedInfo.dateOfBirth) {
        const birthYear = new Date(advancedInfo.dateOfBirth).getFullYear();
        const currentYear = new Date().getFullYear();
        patientAge = (currentYear - birthYear).toString();
      }

      // Convert giới tính sang tiếng Việt cho thân thiện (tùy chọn)
      const genderMap: Record<string, string> = {
        male: 'Nam',
        female: 'Nữ',
        other: 'Khác'
      };

      return {
        _id: room.patientId, // ID bệnh nhân làm ID phòng chat
        patientName: advancedInfo.fullName || "Bệnh nhân ẩn danh", // ✅ Đã sửa thành fullName
        lastMessage: room.lastMessage || "Đã gửi một tập tin",
        updatedAt: room.updatedAt,
        unreadCount: room.unreadCount || 0,
        patientAvatar: advancedInfo.avatar || null,
        patientPhone: advancedInfo.phoneNumber || "Chưa cập nhật", // ✅ Đã sửa thành phoneNumber
        patientAge: patientAge, // ✅ Tự động tính số tuổi từ dateOfBirth
        patientGender: genderMap[advancedInfo.gender || ''] || "Không xác định",
        patientStatus: room.status || "pending"
      };
    }));

    res.status(200).json({
      success: true,
      count: formattedRooms.length,
      data: formattedRooms
    });
  } catch (error: any) {
    console.error('💥 Lỗi tại getChatRooms Controller:', error);
    res.status(500).json({ success: false, message: 'Không thể tải phòng chat', error: error.message });
  }
};
// ─── 4. LẤY LỊCH SỬ CHAT CỦA CHÍNH BỆNH NHÂN (ỨNG DỤNG BỆNH NHÂN) ──────────────
export const getPatientMessages = async (req: Request, res: Response): Promise<void> => {
  try {
    const currentUserId = req.user?.id;
    if (!currentUserId) {
      res.status(401).json({ success: false, message: 'Chưa đăng nhập.' });
      return;
    }

    // 1. Kiểm tra xem bệnh nhân có đang ẩn/xóa phòng này tại máy họ không
    const room = await ChatRoomModel.findOne({ patientId: currentUserId, isDeletedByPatient: false });
    if (!room) {
      // Nếu đã bấm xóa lịch sử, ẩn toàn bộ tin nhắn cũ đi (Trả về mảng rỗng)
      res.status(200).json({ success: true, count: 0, data: [] });
      return;
    }

    // 2. Tìm trực tiếp tin nhắn có roomId bằng chính ID của mình
    const messages = await MessageModel.find({ roomId: currentUserId.toString() })
      .sort({ createdAt: 1 })
      .limit(100);

    res.status(200).json({ success: true, data: messages });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ─── 5. XÓA LỊCH SỬ CHAT PHÍA BỆNH NHÂN (ẨN HỘI THOẠI LOCAL) ──────────────────
export const deletePatientChat = async (req: Request, res: Response): Promise<void> => {
  try {
    const currentUserId = req.user?.id;
    if (!currentUserId) {
      res.status(401).json({ success: false, message: 'Không hợp lệ.' });
      return;
    }

    const result = await ChatRoomModel.findOneAndUpdate(
      { patientId: currentUserId },
      { isDeletedByPatient: true, unreadCount: 0 }
    );

    if (!result) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cuộc trò chuyện để xóa.' });
      return;
    }

    res.status(200).json({ success: true, message: 'Đã xóa lịch sử chat thành công phía bệnh nhân.' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ─── 6. SỬA NỘI DUNG TIN NHẮN (PUT) ─────────────────────────────────────────
export const updateMessage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { messageId, newText } = req.body;
    const currentUserId = req.user?.id;

    const updatedMessage = await MessageModel.findOneAndUpdate(
      { _id: messageId, senderId: currentUserId },
      { text: newText + " (đã chỉnh sửa)" },
      { new: true }
    );

    if (!updatedMessage) {
      res.status(404).json({ success: false, message: 'Không thể sửa tin nhắn này.' });
      return;
    }

    // Phát sự kiện
    const isPatient = req.user?.role !== 'receptionist';
    if (isPatient) {
      emitToRole('receptionist', 'message_updated', updatedMessage);
    } else {
      emitToUser(updatedMessage.roomId.toString(), 'message_updated', updatedMessage);
      emitToRole('receptionist', 'message_updated', updatedMessage);
    }

    res.status(200).json({ success: true, data: updatedMessage });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ─── 7. THU HỒI TIN NHẮN ĐƠN LẺ (DELETE) ────────────────────────────────────
export const deleteSingleMessage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { messageId } = req.params;
    const currentUserId = req.user?.id;

    const deletedMessage = await MessageModel.findOneAndDelete({
      _id: messageId,
      senderId: currentUserId
    });

    if (!deletedMessage) {
      res.status(404).json({ success: false, message: 'Không tìm thấy hoặc bạn không có quyền xóa tin nhắn này.' });
      return;
    }

    // Phát sự kiện
    const isPatient = req.user?.role !== 'receptionist';
    if (isPatient) {
      emitToRole('receptionist', 'message_deleted', { messageId, roomId: deletedMessage.roomId });
    } else {
      emitToUser(deletedMessage.roomId.toString(), 'message_deleted', { messageId, roomId: deletedMessage.roomId });
      emitToRole('receptionist', 'message_deleted', { messageId, roomId: deletedMessage.roomId });
    }

    res.status(200).json({ success: true, message: 'Tin nhắn đã được gỡ bỏ.' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
};