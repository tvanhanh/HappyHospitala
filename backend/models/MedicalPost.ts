import mongoose, { Schema, Document } from 'mongoose';

export interface IComment {
  senderId: mongoose.Types.ObjectId;
  content: string;
  createdAt: Date;
}

export interface IMedicalPost extends Document {
  patientId: mongoose.Types.ObjectId;
  doctorId?: mongoose.Types.ObjectId | null;
  title: string;
  content: string;
  status: 'approved' | 'rejected_spam' | 'rejected_short';
  tags: string[];
  isAnonymous: boolean;
  comments: IComment[];
  createdAt: Date;
  updatedAt: Date;
}

const commentSchema = new Schema<IComment>({
  senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true, trim: true },
  createdAt: { type: Date, default: Date.now }
});

const questionSchema = new Schema<IMedicalPost>({
  patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  doctorId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
  title: { type: String, required: true, trim: true },
  content: { type: String, required: true, trim: true },
  status: {
    type: String,
    enum: ['approved', 'rejected_spam', 'rejected_short'],
    default: 'approved'
  },
  tags: { type: [String], default: [] },
  isAnonymous: { type: Boolean, default: true },
  comments: { type: [commentSchema], default: [] }
}, {
  timestamps: true
});

const MedicalPost = mongoose.model<IMedicalPost>('MedicalPost', questionSchema);
export default MedicalPost;
