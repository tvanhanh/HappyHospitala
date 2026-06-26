import axios from 'axios';
import { Request, Response } from 'express';
import { getAIAction } from '../services/ppo.service';

export const predictDiabetes = async (req: Request, res: Response) => {
  try {
    const userInput = req.body; 

    // LỚP BẢO VỆ 1: Kiểm tra xem Node.js có thực sự nhận được data từ Flutter chưa
    if (!userInput || Object.keys(userInput).length === 0) {
        res.status(400).json({ 
            status: "error", 
            message: "Node.js chưa nhận được dữ liệu (req.body rỗng). Hãy kiểm tra lại Flutter." 
        });
        return;
    }

    // LỚP BẢO VỆ 2: Ép buộc cấu hình Header chuẩn khi gửi sang Flask
    const flaskRes = await axios.post(
        'http://127.0.0.1:5000/api/predict', 
        userInput,
        {
            headers: {
                'Content-Type': 'application/json' // Bắt buộc phải nói rõ với Flask đây là JSON
            }
        }
    );

    res.status(200).json(flaskRes.data);
    return;
    
  } catch (err: any) {
    console.error("Flask error:", err?.response?.data || err.message);
    
    // Xử lý lỗi tinh tế hơn: Trả về đúng mã lỗi của Flask (nếu có) thay vì luôn luôn 500
    const statusCode = err?.response?.status || 500;
    res.status(statusCode).json({ 
        error: 'AI prediction failed', 
        details: err?.response?.data || err.message 
    });
    return;
  }
};

export const predictSkin = async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      res.status(400).json({ success: false, message: "Không tìm thấy file ảnh." });
      return;
    }

    const { age, sex, localization } = req.body;

    const formData = new FormData();
    const fileBlob = new Blob([req.file.buffer as any], { type: req.file.mimetype });
    formData.append('file', fileBlob, req.file.originalname);
    formData.append('age', age || '50');
    formData.append('sex', sex || 'unknown');
    formData.append('localization', localization || 'unknown');

    const flaskRes = await axios.post('http://127.0.0.1:5000/api/predict_skin', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });

    res.status(200).json(flaskRes.data);
  } catch (err: any) {
    console.error("Lỗi predictSkin:", err?.response?.data || err.message);
    res.status(500).json({
      success: false,
      message: 'AI skin prediction failed',
      details: err?.response?.data || err.message
    });
  }
};

export const predictResourcePPO = async (req: Request, res: Response) => {
  const aiResult = await getAIAction(req.body);

  res.json({
    success: true,
    decision: aiResult.action
  });
};


