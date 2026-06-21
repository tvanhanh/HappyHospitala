import { Schema, model, models, Model } from 'mongoose';

export interface IChatRoom extends Document { // Đổi tên interface cho rõ nghĩa
  patientId: Schema.Types.ObjectId;
  lastMessage: string;
  updatedAt: Date;
  unreadCount: number;
  status: 'pending' | 'active' | 'closed';
  isDeletedByPatient: boolean;
}

const ChatRoomSchema = new Schema<IChatRoom>(
  {
    patientId: { 
      type: Schema.Types.ObjectId, 
      ref: 'User', 
      required: true,
      unique: true 
    },
    lastMessage: { type: String, default: 'Chưa có tin nhắn' },
    unreadCount: { type: Number, default: 0 },
    status: { 
      type: String, 
      enum: ['pending', 'active', 'closed'], 
      default: 'pending' 
    },
    isDeletedByPatient: { type: Boolean, default: false }
  },
  
  { timestamps: true }
);

ChatRoomSchema.index({ updatedAt: -1 });

// ĐỔI TÊN Ở ĐÂY: Dùng 'ChatRoom' thay vì 'Room' để không bị trùng với phòng khám bệnh
export const ChatRoomModel = (models.ChatRoom as Model<IChatRoom>) || model<IChatRoom>('ChatRoom', ChatRoomSchema);