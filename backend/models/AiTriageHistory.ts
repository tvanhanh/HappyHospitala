import { Schema, model, Document } from 'mongoose';

export interface IAiTriageMessage {
  role: 'user' | 'ai';
  text: string;
  specialtyId?: string | null;
  specialtyName?: string | null;
  imageUrl?: string | null;
  createdAt?: Date;
}

export interface IAiTriageHistory extends Document {
  userId: string;
  messages: IAiTriageMessage[];
  createdAt: Date;
  updatedAt: Date;
}

const AiTriageHistorySchema = new Schema<IAiTriageHistory>(
  {
    userId: { type: String, required: true, unique: true, index: true },
    messages: [
      {
        role: { type: String, enum: ['user', 'ai'], required: true },
        text: { type: String, required: true },
        specialtyId: { type: String, default: null },
        specialtyName: { type: String, default: null },
        imageUrl: { type: String, default: null },
        createdAt: { type: Date, default: Date.now }
      }
    ]
  },
  {
    timestamps: true
  }
);

export const AiTriageHistoryModel = model<IAiTriageHistory>('AiTriageHistory', AiTriageHistorySchema);
