import mongoose, { Document, Schema } from 'mongoose';

export interface ISpecialtyRoomDoctor extends Document {
  specialtyId: mongoose.Types.ObjectId;
  roomId: mongoose.Types.ObjectId;
  doctorId: mongoose.Types.ObjectId;
}

const specialtyRoomDoctorSchema = new Schema<ISpecialtyRoomDoctor>(
  {
    specialtyId: { type: Schema.Types.ObjectId, ref: 'Specialty', required: true },
    roomId: { type: Schema.Types.ObjectId, ref: 'Room', required: true },
    doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  },
  { timestamps: true }
);

// Ensure unique combination of specialty, room, and doctor
specialtyRoomDoctorSchema.index({ specialtyId: 1, roomId: 1, doctorId: 1 }, { unique: true });

const SpecialtyRoomDoctor = mongoose.model<ISpecialtyRoomDoctor>('SpecialtyRoomDoctor', specialtyRoomDoctorSchema);
export default SpecialtyRoomDoctor;
