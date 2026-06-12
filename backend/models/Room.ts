import mongoose, { Document, Schema } from 'mongoose';

export interface IRoom extends Document {
  roomNumber: string;
  floor: number;
  status: 'Available' | 'Maintenance';
  specialtyId?: mongoose.Types.ObjectId;
}

const roomSchema = new Schema<IRoom>(
  {
    roomNumber: { type: String, required: true, unique: true },
    floor: { type: Number, required: true },
    status: {
      type: String,
      enum: ['Available', 'Maintenance'],
      default: 'Available',
    },
    specialtyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Specialty', required: false },
  },
  { timestamps: true }
);

const Room = mongoose.model<IRoom>('Room', roomSchema);
export default Room;
