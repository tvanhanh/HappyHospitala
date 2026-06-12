import { Request, Response } from 'express';
import Room from '../models/Room';
import RoomAssignment from '../models/RoomAssignment';
import Doctor from '../models/Doctor';
import SpecialtyRoomDoctor from '../models/SpecialtyRoomDoctor';

export const createRoom = async (req: Request, res: Response) => {
  try {
    const room = new Room(req.body);
    const savedRoom = await room.save();

    if (req.body.specialtyId) {
      const activeAssignment = await RoomAssignment.findOne({ roomId: savedRoom._id, status: 'active' });
      if (activeAssignment) {
        await Doctor.findByIdAndUpdate(
          activeAssignment.doctorId,
          { departmentId: req.body.specialtyId, roomId: savedRoom._id }
        );

        await SpecialtyRoomDoctor.findOneAndUpdate(
          { specialtyId: req.body.specialtyId, roomId: savedRoom._id, doctorId: activeAssignment.doctorId },
          { specialtyId: req.body.specialtyId, roomId: savedRoom._id, doctorId: activeAssignment.doctorId },
          { upsert: true, new: true }
        );
      }
    }

    res.status(201).json(savedRoom);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const getRooms = async (req: Request, res: Response) => {
  try {
    const { specialtyId } = req.query;
    const filter = specialtyId ? { specialtyId } : {};
    const rooms = await Room.find(filter).populate('specialtyId');
    res.status(200).json(rooms);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getRoomById = async (req: Request, res: Response) => {
  try {
    const room = await Room.findById(req.params.id);
    if (!room) return res.status(404).json({ message: 'Room not found' });
    res.status(200).json(room);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateRoom = async (req: Request, res: Response) => {
  try {
    const room = await Room.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!room) return res.status(404).json({ message: 'Room not found' });

    if (req.body.specialtyId) {
      const activeAssignment = await RoomAssignment.findOne({ roomId: room._id, status: 'active' });
      if (activeAssignment) {
        await Doctor.findByIdAndUpdate(
          activeAssignment.doctorId,
          { departmentId: req.body.specialtyId, roomId: room._id }
        );

        await SpecialtyRoomDoctor.findOneAndUpdate(
          { specialtyId: req.body.specialtyId, roomId: room._id, doctorId: activeAssignment.doctorId },
          { specialtyId: req.body.specialtyId, roomId: room._id, doctorId: activeAssignment.doctorId },
          { upsert: true, new: true }
        );
      }
    }

    res.status(200).json(room);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteRoom = async (req: Request, res: Response) => {
  try {
    const room = await Room.findByIdAndDelete(req.params.id);
    if (!room) return res.status(404).json({ message: 'Room not found' });
    res.status(200).json({ message: 'Room deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
