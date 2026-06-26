import { Request, Response } from 'express';
import MedicalPost from '../models/MedicalPost';
import User from '../models/User';
import Doctor from '../models/Doctor';
import Groq from 'groq-sdk';
import jwt from 'jsonwebtoken';
import Specialty from '../models/Specialty';

// Helper function to auto-assign tags as a fallback when AI is not available
function autoAssignSpecialty(title: string, content: string): string[] {
  const text = (title + " " + content).toLowerCase();
  const tags: string[] = [];
  if (text.includes("mụn") || text.includes("da") || text.includes("ngứa") || text.includes("chàm") || text.includes("nám") || text.includes("sẹo") || text.includes("dị ứng da")) {
    tags.push("Da liễu");
  }
  if (text.includes("tiểu đường") || text.includes("tuyến giáp") || text.includes("nội tiết") || text.includes("hormone") || text.includes("bướu cổ") || text.includes("insulin")) {
    tags.push("Nội tiết");
  }
  if (text.includes("răng") || text.includes("nướu") || text.includes("sâu răng") || text.includes("nha khoa") || text.includes("niềng răng") || text.includes("nhổ răng")) {
    tags.push("Nha khoa");
  }
  if (text.includes("tim") || text.includes("huyết áp") || text.includes("mạch") || text.includes("đau ngực") || text.includes("đột quỵ")) {
    tags.push("Tim mạch");
  }
  if (text.includes("xương") || text.includes("khớp") || text.includes("cơ xương") || text.includes("đau lưng") || text.includes("thoái hóa")) {
    tags.push("Cơ xương khớp");
  }
  if (text.includes("nhi") || text.includes("trẻ em") || text.includes("bé") || text.includes("sơ sinh") || text.includes("chích ngừa")) {
    tags.push("Nhi khoa");
  }
  if (text.includes("tai") || text.includes("mũi") || text.includes("họng") || text.includes("amidan") || text.includes("xoang") || text.includes("ho")) {
    tags.push("Tai Mũi Họng");
  }
  if (text.includes("mắt") || text.includes("thị lực") || text.includes("cận thị") || text.includes("kính")) {
    tags.push("Mắt");
  }
  if (text.includes("thần kinh") || text.includes("đau đầu") || text.includes("chóng mặt") || text.includes("mất ngủ")) {
    tags.push("Thần kinh");
  }
  if (text.includes("tiêu hóa") || text.includes("dạ dày") || text.includes("đau bụng") || text.includes("trào ngược") || text.includes("gan")) {
    tags.push("Tiêu hóa");
  }
  if (tags.length === 0) {
    tags.push("Tổng quát");
  }
  return tags;
}

// Q&A Automatic Moderation Middleware logic
export const autoModerateMedicalPost = async (req: Request, res: Response, next: () => void): Promise<any> => {
  try {
    const { title, content } = req.body;
    const patientId = req.user?.id;

    if (!title || !content) {
      return res.status(400).json({ message: "Tiêu đề và nội dung câu hỏi là bắt buộc." });
    }

    // Rule 1: Validate Length
    if (title.trim().length < 15 || title.trim().length > 100) {
      return res.status(400).json({ message: "Tiêu đề phải từ 15 đến 100 ký tự." });
    }
    if (content.trim().length < 50) {
      return res.status(400).json({ message: "Nội dung câu hỏi phải dài tối thiểu 50 ký tự để mô tả rõ triệu chứng." });
    }

    // Rule 2: Profanity Filter
    const forbiddenKeywords = [
      'đm', 'đéo', 'vcl', 'dcm', 'clgt', 'chửi thề', 'thô tục', 'quảng cáo', 'lừa đảo', 
      'cá độ', 'cờ bạc', 'sex', 'đồi trụy', 'đ.m', 'đ.é.o', 'v.c.l', 'khốn nạn', 'mất dạy'
    ];
    const textToScan = (title + ' ' + content).toLowerCase();
    const containsProfanity = forbiddenKeywords.some(keyword => {
      const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(`\\b${escaped}\\b|${escaped}`, 'i');
      return regex.test(textToScan);
    });

    if (containsProfanity) {
      return res.status(400).json({ message: "Nội dung chứa từ ngữ cấm hoặc không phù hợp. Vui lòng chỉnh sửa lại." });
    }

    // Rule 3: Anti-Spam (Rate limiting)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const hourlyMedicalPostCount = await MedicalPost.countDocuments({
      patientId,
      createdAt: { $gte: oneHourAgo }
    });

    if (hourlyMedicalPostCount >= 100) {
      return res.status(400).json({ message: "Bạn chỉ được gửi tối đa 3 câu hỏi trong vòng 1 giờ. Vui lòng thử lại sau." });
    }

    // Passed moderation rules, proceed to AI Check and creation
    next();
  } catch (error: any) {
    console.error("Auto moderation error:", error);
    res.status(500).json({ message: "Lỗi hệ thống trong quá trình kiểm duyệt câu hỏi.", error: error.message });
  }
};

// Nhớ thêm import này ở đầu file nhé:
// import Specialty from '../models/Specialty';

export const createMedicalPost = async (req: Request, res: Response): Promise<any> => {
  try {
    const { title, content, isAnonymous, specialtyTag } = req.body;
    const patientId = req.user?.id;

    let status: 'approved' | 'rejected_spam' | 'rejected_short' = 'approved';
    let finalTags: string[] = [];

    // 1. Lấy danh sách chuyên khoa từ DB để mớm cho AI (Giống hệt hàm triage)
    const specialties = await Specialty.find({}, 'name').lean();
    const specialtyListText = specialties.map((s: any) => `- ${s.name}`).join('\n');

    // Nếu người dùng tự chọn khoa trên app thì ưu tiên giữ nguyên, nếu không thì để AI tự phân
    if (specialtyTag) {
      finalTags = [specialtyTag];
    }

    // 2. AI Check & Phân luồng (Groq SDK)
    const apiKey = process.env.GROQ_API_KEY;
    if (apiKey) {
      try {
        const groq = new Groq({ apiKey });
        
        // Cập nhật System Prompt: Ép AI chỉ được chọn khoa trong DB
        const systemPrompt = `Đóng vai một trợ lý y tế. Hãy phân tích nội dung câu hỏi sau:
        1. Nó có phải là một câu hỏi y tế hợp lệ không? Triệu chứng có được mô tả rõ ràng không? 
        2. Dựa vào danh sách chuyên khoa dưới đây của phòng khám, hãy xếp câu hỏi vào 1 chuyên khoa phù hợp nhất:
        ${specialtyListText}
        
        Trả về DUY NHẤT một chuỗi JSON với định dạng chính xác sau (không thêm văn bản khác):
        { 
          "isValid": boolean, 
          "reason": "chuỗi giải thích ngắn gọn", 
          "specialty": "Tên chuyên khoa chính xác từ danh sách trên (hoặc null nếu không xác định được)" 
        }`;

        const response = await groq.chat.completions.create({
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `Tiêu đề: "${title}"\nNội dung: "${content}"` }
          ],
          model: 'llama-3.3-70b-versatile',
          temperature: 0.1,
          response_format: { type: "json_object" }
        });

        const resultJson = JSON.parse(response.choices[0]?.message?.content?.trim() || "{}");
        
        // Nếu AI đánh giá câu hỏi rác/không hợp lệ -> Chặn ngay
        if (resultJson.isValid === false) {
          return res.status(400).json({
            message: resultJson.reason || "Vui lòng mô tả chi tiết triệu chứng y tế của bạn hơn."
          });
        }

        // Nếu người dùng không chọn khoa -> Lấy khoa AI phân tích được đối chiếu với DB
        if (!specialtyTag && resultJson.specialty) {
          const matchedSpecialty = specialties.find(
            (s: any) => resultJson.specialty.toLowerCase().includes(s.name.toLowerCase()) || 
                        s.name.toLowerCase().includes(resultJson.specialty.toLowerCase())
          );
          
          if (matchedSpecialty) {
            finalTags = [matchedSpecialty.name]; // Gắn đúng tên khoa trong DB
          } else {
            finalTags = ["Tổng quát"]; // Trượt thì cho vào Tổng quát
          }
        }
      } catch (aiErr) {
        console.error("Lỗi kiểm tra AI (Groq), fallback:", aiErr);
      }
    }

    // Nếu không có API Key, lỗi AI, hoặc AI không tìm ra khoa -> Mặc định là Tổng quát
    if (finalTags.length === 0) {
      finalTags = ["Tổng quát"];
    }

    // 3. Lưu vào MongoDB (Bảng medicalPosts)
    const newMedicalPost = new MedicalPost({
      patientId,
      doctorId: null,
      title: title.trim(),
      content: content.trim(),
      isAnonymous: isAnonymous === true,
      tags: finalTags,
      status,
      comments: []
    });

    await newMedicalPost.save();

    res.status(201).json({
      message: "Câu hỏi đã được phê duyệt và đăng thành công.",
      post: newMedicalPost
    });
  } catch (error: any) {
    console.error("Lỗi tạo câu hỏi:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};
// 2. Fetch all approved posts (Public/All with masking & Role-Based Filtering)
export const getApprovedPosts = async (req: Request, res: Response): Promise<any> => {
  try {
    const { specialtyTag } = req.query;
    const filter: any = { status: 'approved' };

    // Bóc tách JWT để lấy ID và Role của người đang gọi API
    let requesterId: string | null = null;
    let requesterRole: string | null = null;
    
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
        requesterId = (decoded.id || decoded._id)?.toString() || null;
        requesterRole = decoded.role || null; // Lấy thêm Role từ token
      } catch (err) {
        // Token lỗi hoặc hết hạn thì bỏ qua
      }
    }

    // 🔥 LOGIC PHÂN QUYỀN TRUY CẬP (ROLE-BASED FILTER)
    if (requesterRole === 'doctor' && requesterId) {
      // 1. Nếu là BÁC SĨ: Tìm chuyên khoa của bác sĩ trong DB
      const doctor = await Doctor.findById(requesterId).populate('specialtyId');
      if (doctor) {
        // Lấy tên chuyên khoa (Tùy thuộc vào Schema của ông, giả sử là specialtyId.name hoặc specialty)
        const doctorSpecialtyName = (doctor as any).specialtyId?.name || (doctor as any).specialty || "Tổng quát";
        
        // Ép cứng filter: Bác sĩ chỉ thấy câu hỏi của khoa mình
        filter.tags = doctorSpecialtyName;
      }
    } else if (specialtyTag) {
      // 2. Nếu là BỆNH NHÂN (hoặc khách): Lọc theo chuyên khoa họ chọn trên App
      filter.tags = specialtyTag;
    }

    // Fetch dữ liệu từ DB
    const medicalPosts = await MedicalPost.find(filter)
      .populate('patientId', 'fullName avatar email phoneNumber')
      .populate('comments.senderId', 'fullName role avatar')
      .sort({ createdAt: -1 })
      .lean();

    // Data Masking Logic (Giữ nguyên vẹn của ông)
    const maskedMedicalPosts = medicalPosts.map((q: any) => {
      q.specialtyTag = q.tags && q.tags.length > 0 ? q.tags[0] : "Tổng quát";
      
      q.answers = (q.comments || []).map((c: any) => {
        let docName = c.senderId?.fullName || "Bác sĩ Happy Clinic";
        if (q.isAnonymous && c.senderId?.role === 'patient') {
          const isOwner = requesterId && q.patientId && q.patientId._id.toString() === requesterId;
          if (!isOwner) {
            docName = "Bệnh nhân ẩn danh";
          }
        }
        return {
          doctorId: c.senderId?._id || c.senderId,
          doctorName: docName,
          doctorTitle: c.senderId?.role === 'doctor' ? 'Bác sĩ' : 'Người hỏi',
          responseText: c.content,
          createdAt: c.createdAt
        };
      });

      if (q.isAnonymous) {
        const isOwner = requesterId && q.patientId && q.patientId._id.toString() === requesterId;
        if (!isOwner) {
          if (q.patientId) {
            q.patientId = {
              _id: q.patientId._id,
              fullName: "Bệnh nhân ẩn danh",
              avatar: null
            };
          }
          q.patientName = "Bệnh nhân ẩn danh";
          q.patientAvatar = null;
        } else {
          if (q.patientId) {
            q.patientName = q.patientId.fullName;
            q.patientAvatar = q.patientId.avatar;
          }
        }
      } else {
        if (q.patientId) {
          q.patientName = q.patientId.fullName;
          q.patientAvatar = q.patientId.avatar;
        }
      }
      return q;
    });

    res.status(200).json(maskedMedicalPosts);
  } catch (error: any) {
    console.error("Lỗi lấy danh sách câu hỏi:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};
// 3. Create a comment (discussion) on a medicalPost
export const createComment = async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const user = req.user; // populated by verifyToken

    if (!user) {
      return res.status(401).json({ message: "Bạn chưa đăng nhập." });
    }

    if (!content || content.trim() === '') {
      return res.status(400).json({ message: "Nội dung bình luận không được để trống." });
    }

    const medicalPost = await MedicalPost.findById(id);
    if (!medicalPost) {
      return res.status(404).json({ message: "Không tìm thấy câu hỏi tư vấn." });
    }

    // Role-based authorization rules
    if (user.role === 'admin') {
      return res.status(403).json({ message: "Tài khoản admin chỉ được phép xem thảo luận." });
    }

    if (user.role === 'patient') {
      if (user.id !== medicalPost.patientId.toString()) {
        return res.status(403).json({ message: "Chỉ người đặt câu hỏi mới được phép bình luận." });
      }
    }

    if (user.role === 'doctor') {
      if (medicalPost.doctorId) {
        if (user.id !== medicalPost.doctorId.toString()) {
          return res.status(403).json({ message: "Chỉ bác sĩ phụ trách câu hỏi này mới được phép bình luận." });
        }
      } else {
        // Dynamically assign this doctor as the responsible doctor
        medicalPost.doctorId = user.id as any;
      }
    }

    // Add comment
    medicalPost.comments.push({
      senderId: user.id as any,
      content: content.trim(),
      createdAt: new Date()
    });

    await medicalPost.save();

    // Map back updated medicalPost structure for client
    const updatedPost = await MedicalPost.findById(id)
      .populate('patientId', 'fullName avatar email phoneNumber')
      .populate('comments.senderId', 'fullName role avatar')
      .lean();

    if (updatedPost) {
      (updatedPost as any).specialtyTag = updatedPost.tags && updatedPost.tags.length > 0 ? updatedPost.tags[0] : "Tổng quát";
      (updatedPost as any).answers = (updatedPost.comments || []).map((c: any) => {
        let docName = c.senderId?.fullName || "Bác sĩ Happy Clinic";
        if (updatedPost.isAnonymous && c.senderId?.role === 'patient') {
          const isOwner = user && updatedPost.patientId && updatedPost.patientId._id.toString() === user.id;
          if (!isOwner) {
            docName = "Bệnh nhân ẩn danh";
          }
        }
        return {
          doctorId: c.senderId?._id || c.senderId,
          doctorName: docName,
          doctorTitle: c.senderId?.role === 'doctor' ? 'Bác sĩ' : 'Người hỏi',
          responseText: c.content,
          createdAt: c.createdAt
        };
      });
    }

    res.status(200).json({
      message: "Bình luận gửi thành công.",
      post: updatedPost
    });
  } catch (error: any) {
    console.error("Lỗi tạo bình luận:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};


// Thêm API này dành Tách biệt riêng cho Bác sĩ xem theo chuyên khoa
export const getDoctorSpecialtyPosts = async (req: Request, res: Response): Promise<any> => {
  try {
    const userId = req.user?.id;
    
    if (!userId || req.user?.role !== 'doctor') {
      return res.status(403).json({ message: "Chỉ bác sĩ mới có quyền truy cập tính năng này." });
    }

    // 1. Tìm thông tin bác sĩ trong DB để biết họ thuộc chuyên khoa nào
    // LƯU Ý: Chỗ `doctor.specialty` ông nhớ check lại Schema Doctor của ông xem lưu chuyên khoa ở field nào nhé.
    const doctor = await Doctor.findById(userId).populate('specialtyId'); 
    if (!doctor) {
      return res.status(404).json({ message: "Không tìm thấy hồ sơ bác sĩ." });
    }

    // Lấy tên chuyên khoa của bác sĩ (Sửa lại trường này cho khớp với cấu trúc DB của ông)
    // Ví dụ: doctor.specialtyId.name hoặc doctor.department...
    const doctorSpecialtyName = (doctor as any).specialtyId?.name || (doctor as any).specialty || "Tổng quát";

    // 2. Ép cứng Filter: Chỉ lấy các câu hỏi 'approved' và có 'tags' trùng với chuyên khoa của bác sĩ
    const filter: any = { 
      status: 'approved',
      tags: doctorSpecialtyName 
    };

    // 3. Fetch dữ liệu từ DB
    const medicalPosts = await MedicalPost.find(filter)
      .populate('patientId', 'fullName avatar email phoneNumber')
      .populate('comments.senderId', 'fullName role avatar')
      .sort({ createdAt: -1 })
      .lean();

    // 4. Data Masking Logic (Che giấu danh tính y hệt hàm public)
    const maskedMedicalPosts = medicalPosts.map((q: any) => {
      q.specialtyTag = q.tags && q.tags.length > 0 ? q.tags[0] : "Tổng quát";
      
      q.answers = (q.comments || []).map((c: any) => {
        let docName = c.senderId?.fullName || "Bác sĩ Happy Clinic";
        if (q.isAnonymous && c.senderId?.role === 'patient') {
          docName = "Bệnh nhân ẩn danh"; // Bác sĩ xem thì bệnh nhân luôn bị ẩn danh nếu isAnonymous = true
        }
        return {
          doctorId: c.senderId?._id || c.senderId,
          doctorName: docName,
          doctorTitle: c.senderId?.role === 'doctor' ? 'Bác sĩ' : 'Người hỏi',
          responseText: c.content,
          createdAt: c.createdAt
        };
      });

      if (q.isAnonymous) {
        if (q.patientId) {
          q.patientId = {
            _id: q.patientId._id,
            fullName: "Bệnh nhân ẩn danh",
            avatar: null
          };
        }
        q.patientName = "Bệnh nhân ẩn danh";
        q.patientAvatar = null;
      } else {
        if (q.patientId) {
          q.patientName = q.patientId.fullName;
          q.patientAvatar = q.patientId.avatar;
        }
      }
      return q;
    });

    res.status(200).json(maskedMedicalPosts);
  } catch (error: any) {
    console.error("Lỗi lấy danh sách câu hỏi theo khoa của bác sĩ:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};
// Answer MedicalPost legacy wrapper mapping to createComment
export const answerMedicalPost = async (req: Request, res: Response): Promise<any> => {
  // Map legacy body responseText to content
  req.body.content = req.body.responseText;
  return createComment(req, res);
};

// 4. Change post status (Admin only)
export const updatePostStatus = async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['approved', 'rejected_spam', 'rejected_short'].includes(status)) {
      return res.status(400).json({ message: "Trạng thái không hợp lệ." });
    }

    const medicalPost = await MedicalPost.findById(id);
    if (!medicalPost) {
      return res.status(404).json({ message: "Không tìm thấy câu hỏi tư vấn." });
    }

    medicalPost.status = status;
    await medicalPost.save();

    res.status(200).json({
      message: `Đã cập nhật trạng thái câu hỏi thành công: ${status}.`,
      post: medicalPost
    });
  } catch (error: any) {
    console.error("Lỗi phê duyệt câu hỏi:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};

// 5. Admin get all posts (Admin only)
export const getAllPostsAdmin = async (req: Request, res: Response): Promise<any> => {
  try {
    const medicalPosts = await MedicalPost.find()
      .populate('patientId', 'fullName email')
      .sort({ createdAt: -1 })
      .lean();

    const formatted = medicalPosts.map((q: any) => {
      q.specialtyTag = q.tags && q.tags.length > 0 ? q.tags[0] : "Tổng quát";
      return q;
    });

    res.status(200).json(formatted);
  } catch (error: any) {
    console.error("Lỗi lấy toàn bộ danh sách Q&A admin:", error);
    res.status(500).json({ message: "Lỗi hệ thống.", error: error.message });
  }
};
