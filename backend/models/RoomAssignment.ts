import mongoose, { Document, Schema } from 'mongoose';

export interface IRoomAssignment extends Document {
  doctorId: mongoose.Types.ObjectId;
  roomId: mongoose.Types.ObjectId;
  workingDays: string[];
  shift: string;
  status: 'active' | 'inactive';
}

const roomAssignmentSchema = new Schema<IRoomAssignment>(
  {
    doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: true },
    roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Room', required: true },
    workingDays: { type: [String], default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'] },
    shift: { type: String, enum: ['Morning', 'Afternoon', 'Full'], default: 'Full' },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: true }
);

roomAssignmentSchema.index({ doctorId: 1, roomId: 1 }, { unique: true });

const RoomAssignment = mongoose.model<IRoomAssignment>('RoomAssignment', roomAssignmentSchema);
export default RoomAssignment;
