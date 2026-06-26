import { Request, Response } from 'express';
import Groq from 'groq-sdk';
import Specialty from '../models/Specialty';
import User from '../models/User';
import { AiTriageHistoryModel } from '../models/AiTriageHistory';
import { MessageModel } from '../models/Message';
import { ChatRoomModel } from '../models/Room_mes_model';
import { emitToRole, emitToUser } from '../services/socket.service';

/**
 * Controller xử lý chẩn đoán và phân luồng chuyên khoa bằng AI (Groq Llama-3)
 * Hỗ trợ lưu lịch sử trò chuyện vĩnh viễn vào MongoDB.
 */
export const triage = async (req: Request, res: Response): Promise<any> => {
  try {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ message: 'GROQ_API_KEY chưa được cấu hình trong .env backend!' });
    }

    const { message, history } = req.body;

    if (!message) {
      return res.status(400).json({ message: 'Tin nhắn (message) không được để trống' });
    }

    // 1. Lấy danh sách các chuyên khoa đang hoạt động trong DB
    const specialties = await Specialty.find({}, 'name _id imageUrl').lean();
    if (!specialties || specialties.length === 0) {
      return res.status(500).json({ message: 'Không tìm thấy danh sách chuyên khoa trong DB.' });
    }

    const specialtyListText = specialties.map(s => `- ${s.name}`).join('\n');

    // 2. Tính tuổi và giới tính người dùng hiện tại từ DB để hỗ trợ prompt y khoa
    let ageText = "không rõ";
    let genderText = "không rõ";
    let isAdult = true; // mặc định coi là người lớn để phòng ngừa gợi ý khoa nhi sai

    if (req.user) {
      const user = await User.findById(req.user.id);
      if (user) {
        if (user.dateOfBirth) {
          const birthDate = new Date(user.dateOfBirth);
          const today = new Date();
          let age = today.getFullYear() - birthDate.getFullYear();
          const m = today.getMonth() - birthDate.getMonth();
          if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
          }
          ageText = `${age} tuổi`;
          if (age < 16) {
            isAdult = false;
          }
        }
        if (user.gender) {
          genderText = user.gender === 'male' ? 'Nam' : user.gender === 'female' ? 'Nữ' : 'Khác';
        }
      }
    }

    const patientContext = req.user 
      ? `Bệnh nhân hiện tại: Giới tính ${genderText}, ${ageText} (${isAdult ? 'Người lớn' : 'Trẻ em'}). `
      : '';

    // 3. Định nghĩa System Prompt hướng dẫn phân khoa
    const systemPrompt = `Bạn là một trợ lý y tế thông minh của phòng khám.
Dưới đây là danh sách các chuyên khoa hiện có tại phòng khám:
${specialtyListText}

${patientContext}Dựa vào các triệu chứng hiện tại, lịch sử trò chuyện, và thông tin cá nhân của bệnh nhân (tuổi và giới tính), hãy xác định bệnh nhân nên khám ở khoa nào trong danh sách trên.
- ĐẶC BIỆT LƯU Ý: Chỉ gợi ý Khoa Nhi (hoặc Pediatrics) nếu bệnh nhân là trẻ em (thường dưới 16 tuổi). Nếu bệnh nhân đã lớn tuổi (ví dụ: người lớn từ 16 tuổi trở lên), các triệu chứng thông thường như sốt, ho, đau đầu phải được đưa vào Khoa Nội (hoặc chuyên khoa tương ứng dành cho người lớn), TUYỆT ĐỐI không gợi ý Khoa Nhi.
Chỉ trả về duy nhất tên của khoa đó (chính xác từng chữ như trong danh sách). Nếu triệu chứng không rõ ràng, không liên quan đến bất kỳ chuyên khoa nào ở trên, hoặc chưa đủ thông tin, hãy trả về 'Không xác định'. Tuyệt đối không giải thích thêm hay thêm dấu ngoặc kép.`;

    const groq = new Groq({ apiKey });

    // 4. Khởi tạo mảng tin nhắn gửi tới Groq API
    const groqMessages: any[] = [
      { role: 'system', content: systemPrompt }
    ];

    // Ánh xạ lịch sử trò chuyện từ Client lên API (ai -> assistant, user -> user)
    if (history && Array.isArray(history)) {
      history.forEach((msg: any) => {
        const role = msg.role === 'ai' ? 'assistant' : 'user';
        const content = msg.text || '';
        if (content) {
          groqMessages.push({ role, content });
        }
      });
    }

    // Đưa tin nhắn hiện tại của User vào cuối hàng đợi tin nhắn
    groqMessages.push({ role: 'user', content: message });

    // Gọi Groq API (sử dụng model Llama 3)
    const chatCompletion = await groq.chat.completions.create({
      messages: groqMessages,
      model: 'llama-3.3-70b-versatile',
    });

    const textResponse = chatCompletion.choices[0]?.message?.content?.trim() || "";

    // 5. So khớp phản hồi của Groq với danh sách chuyên khoa
    const matchedSpecialty = specialties.find(
      s => textResponse.toLowerCase().includes(s.name.toLowerCase()) || 
           s.name.toLowerCase().includes(textResponse.toLowerCase())
    );

    const aiResponseText = matchedSpecialty
      ? `Dựa trên triệu chứng và trao đổi của bạn, tôi khuyên bạn nên thăm khám tại chuyên khoa: ${matchedSpecialty.name}. Bạn có thể đặt lịch khám ngay bằng nút bên dưới.\n\n⚠️ Lưu ý: Trợ lý AI không kê đơn thuốc. Vui lòng không tự ý mua hay uống thuốc khi chưa có chỉ định của Bác sĩ.`
      : 'Tôi chưa xác định rõ triệu chứng này phù hợp với chuyên khoa nào trong hệ thống của phòng khám. Vui lòng kết nối trực tiếp với Lễ tân để được hỗ trợ tốt nhất.\n\n⚠️ Lưu ý: Trợ lý AI không kê đơn thuốc. Vui lòng không tự ý mua hay uống thuốc khi chưa có chỉ định của Bác sĩ.';

    const finalSpecialtyId = matchedSpecialty ? matchedSpecialty._id.toString() : null;
    const finalSpecialtyName = matchedSpecialty ? matchedSpecialty.name : null;
    const finalImageUrl = matchedSpecialty ? matchedSpecialty.imageUrl : null;

    // 6. Lưu vĩnh viễn cuộc hội thoại vào MongoDB nếu người dùng đã đăng nhập
    if (req.user) {
      const userId = req.user.id;
      const newMessages = [
        {
          role: 'user' as const,
          text: message,
          specialtyId: null,
          specialtyName: null,
          imageUrl: null,
        },
        {
          role: 'ai' as const,
          text: aiResponseText,
          specialtyId: finalSpecialtyId,
          specialtyName: finalSpecialtyName,
          imageUrl: finalImageUrl,
        }
      ];

      await AiTriageHistoryModel.findOneAndUpdate(
        { userId },
        { 
          $push: { messages: { $each: newMessages } } 
        },
        { upsert: true, new: true }
      );
    }

    return res.status(200).json({ 
      specialtyId: finalSpecialtyId, 
      specialtyName: finalSpecialtyName,
      imageUrl: finalImageUrl,
      message: aiResponseText
    });

  } catch (error: any) {
    console.error('Lỗi gọi Groq:', error);
    return res.status(500).json({ message: 'Có lỗi xảy ra khi gọi AI', error: error.message });
  }
};

/**
 * Lấy lịch sử trò chuyện AI Triage của người dùng từ MongoDB
 */
export const getHistory = async (req: Request, res: Response): Promise<any> => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: 'Chưa đăng nhập. Không có quyền truy cập.' });
    }
    const userId = req.user.id;
    const historyDoc = await AiTriageHistoryModel.findOne({ userId });

    if (!historyDoc || historyDoc.messages.length === 0) {
      // Trả về tin nhắn chào mừng mặc định nếu chưa có lịch sử
      return res.status(200).json([
        {
          role: 'ai',
          text: 'Chào bạn, tôi là Trợ lý Y tế AI. Bạn đang gặp phải những triệu chứng gì? Hãy mô tả chi tiết (ví dụ: đau đầu, sốt, ho nhiều vào ban đêm) để tôi tư vấn chuyên khoa phù hợp nhé!',
          specialtyId: null,
          specialtyName: null,
          imageUrl: null,
        }
      ]);
    }

    return res.status(200).json(historyDoc.messages);
  } catch (error: any) {
    console.error('Lỗi lấy lịch sử chat:', error);
    return res.status(500).json({ message: 'Có lỗi xảy ra khi lấy lịch sử chat', error: error.message });
  }
};

/**
 * Xóa lịch sử trò chuyện AI Triage của người dùng khỏi MongoDB
 */
export const clearHistory = async (req: Request, res: Response): Promise<any> => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: 'Chưa đăng nhập. Không có quyền truy cập.' });
    }
    const userId = req.user.id;
    await AiTriageHistoryModel.deleteOne({ userId });

    return res.status(200).json({ message: 'Đã xóa lịch sử trò chuyện AI thành công.' });
  } catch (error: any) {
    console.error('Lỗi xóa lịch sử chat:', error);
    return res.status(500).json({ message: 'Có lỗi xảy ra khi xóa lịch sử chat', error: error.message });
  }
};

/**
 * Lấy danh sách các cuộc hội thoại triage thất bại (specialtyId === null)
 * để chuyển giao hỗ trợ trực tiếp (Lễ tân)
 */
export const getHandoffSessions = async (req: Request, res: Response): Promise<any> => {
  try {
    if (!req.user || req.user.role !== 'receptionist') {
      return res.status(403).json({ message: 'Không có quyền truy cập danh sách bàn giao.' });
    }

    const histories = await AiTriageHistoryModel.find().lean();
    const handoffs: any[] = [];

    for (const history of histories) {
      const messages = history.messages || [];
      if (messages.length === 0) continue;

      // Tìm tin nhắn cuối cùng của AI
      const aiMsgs = messages.filter((m: any) => m.role === 'ai');
      if (aiMsgs.length === 0) continue;

      const lastAiMsg = aiMsgs[aiMsgs.length - 1];

      // Nếu AI phản hồi với specialtyId là null/không xác định
      if (lastAiMsg.specialtyId === null || lastAiMsg.specialtyId === 'null' || !lastAiMsg.specialtyId) {
        // Lấy thông tin cơ bản của bệnh nhân
        const patient = await User.findById(history.userId).select('fullName avatar phoneNumber dateOfBirth gender').lean();
        if (!patient) continue;

        // Lấy triệu chứng cuối cùng của bệnh nhân gửi
        const userMsgs = messages.filter((m: any) => m.role === 'user');
        const lastUserMsg = userMsgs.length > 0 ? userMsgs[userMsgs.length - 1] : null;

        handoffs.push({
          patientId: history.userId,
          patientName: patient.fullName || "Bệnh nhân ẩn danh",
          patientAvatar: patient.avatar || "",
          patientPhone: patient.phoneNumber || "Chưa cập nhật",
          patientGender: patient.gender === 'male' ? 'Nam' : patient.gender === 'female' ? 'Nữ' : 'Khác',
          patientDOB: patient.dateOfBirth ? new Date(patient.dateOfBirth).toLocaleDateString('vi-VN') : 'Chưa rõ',
          symptomsPreview: lastUserMsg ? lastUserMsg.text : "Cần hỗ trợ trực tiếp từ lễ tân",
          updatedAt: history.updatedAt,
        });
      }
    }

    // Sắp xếp thời gian giảm dần
    handoffs.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

    return res.status(200).json({
      success: true,
      count: handoffs.length,
      data: handoffs
    });
  } catch (error: any) {
    console.error('💥 Lỗi getHandoffSessions:', error);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy danh sách bàn giao', error: error.message });
  }
};

/**
 * Lễ tân xác nhận tiếp nhận cuộc trò chuyện trực tiếp
 */
export const initiateHandoffChat = async (req: Request, res: Response): Promise<any> => {
  try {
    if (!req.user || req.user.role !== 'receptionist') {
      return res.status(403).json({ message: 'Chỉ lễ tân mới được tiếp nhận cuộc trò chuyện.' });
    }

    const { patientId } = req.body;
    if (!patientId) {
      return res.status(400).json({ message: 'Thiếu patientId của bệnh nhân.' });
    }

    const patient = await User.findById(patientId);
    if (!patient) {
      return res.status(404).json({ message: 'Không tìm thấy bệnh nhân.' });
    }

    // Khởi tạo/Cập nhật phòng chat cho bệnh nhân
    const room = await ChatRoomModel.findOneAndUpdate(
      { patientId },
      {
        patientId,
        lastMessage: "Đã tiếp nhận yêu cầu hỗ trợ",
        updatedAt: new Date(),
        isDeletedByPatient: false,
        status: 'active',
        unreadCount: 0
      },
      { upsert: true, new: true }
    );

    // Gửi tin nhắn chào mừng tự động của lễ tân
    const welcomeText = `Xin chào ${patient.fullName || 'bạn'}, tôi là lễ tân hỗ trợ trực ban. Tôi đã tiếp nhận yêu cầu hỗ trợ trực tiếp của bạn. Hãy chia sẻ vấn đề của bạn để tôi tư vấn giải pháp phù hợp nhé!`;
    const welcomeMessage = new MessageModel({
      senderId: req.user.id,
      roomId: patientId,
      text: welcomeText,
      imageUrl: null,
      fileType: null,
    });
    await welcomeMessage.save();

    // Cập nhật tin nhắn cuối cùng của phòng chat
    room.lastMessage = welcomeText;
    await room.save();

    // Phát sự kiện cập nhật qua Socket.IO
    emitToUser(patientId.toString(), 'new_message', welcomeMessage);
    emitToRole('receptionist', 'new_message', welcomeMessage);

    return res.status(200).json({
      success: true,
      message: 'Tiếp nhận cuộc trò chuyện thành công.',
      data: room
    });
  } catch (error: any) {
    console.error('💥 Lỗi initiateHandoffChat:', error);
    return res.status(500).json({ success: false, message: 'Lỗi server khi tiếp nhận cuộc trò chuyện', error: error.message });
  }
};

