import { Schema, model, Document } from 'mongoose';

// 1. Định nghĩa Interface cho TypeScript
export interface IMessage extends Document {
  roomId: string;
  senderId: string;
  text: string;
  imageUrl?: string;    // Chứa chuỗi Base64 hoặc link Cloud của File
  fileType?: string;   // Lưu kiểu file (image/png, application/pdf, v.v.)
  createdAt: Date;
}

// 2. Định nghĩa Schema thật cho MongoDB
const MessageSchema = new Schema<IMessage>(
  {
   roomId: { type: String, required: true, index: true },
    senderId: { type: String, required: true, index: true }, // Index để câu lệnh tìm kiếm tin nhắn chạy siêu nhanh
    text: { type: String, required: true },
    imageUrl: { type: String, default: null },
    fileType: { type: String, default: null },
  },
  { 
    timestamps: { createdAt: true, updatedAt: false } // Tự động sinh trường 'createdAt' (thay cho timestamp)
  }
);

export const MessageModel = model<IMessage>('Message', MessageSchema);