import { Request, Response } from 'express';
import Room from '../models/Room';
import RoomAssignment from '../models/RoomAssignment';
import Doctor from '../models/Doctor';
import SpecialtyRoomDoctor from '../models/SpecialtyRoomDoctor';

export const createRoom = async (req: Request, res: Response): Promise<void> => {
  try {
    // 1. BACKEND VALIDATION
    const { roomNumber } = req.body;
    if (roomNumber) {
      const existingRoom = await Room.findOne({ roomNumber });
      if (existingRoom) {
        res.status(409).json({ message: 'Số phòng này đã tồn tại trong hệ thống!' });
        return; // Thoát hàm đúng chuẩn TypeScript
      }
    }

    const room = new Room(req.body);
    const savedRoom = await room.save();

    if (req.body.specialtyId) {
      const activeAssignment = await RoomAssignment.findOne({ roomId: savedRoom._id, status: 'active' });
      if (activeAssignment) {
        await Doctor.findByIdAndUpdate(
          activeAssignment.doctorId,
          { specialtyId: req.body.specialtyId, roomId: savedRoom._id }
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

export const getRooms = async (req: Request, res: Response): Promise<void> => {
  try {
    const { specialtyId } = req.query;
    const filter = specialtyId ? { specialtyId } : {};
    const rooms = await Room.find(filter).populate('specialtyId');
    res.status(200).json(rooms);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getRoomById = async (req: Request, res: Response): Promise<void> => {
  try {
    const room = await Room.findById(req.params.id);
    if (!room) {
      res.status(404).json({ message: 'Room not found' });
      return;
    }
    res.status(200).json(room);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateRoom = async (req: Request, res: Response): Promise<void> => {
  try {
    const { roomNumber } = req.body;
    const roomIdToUpdate = req.params.id;

    // 1. BACKEND VALIDATION
    if (roomNumber) {
      const existingRoom = await Room.findOne({ 
        roomNumber: roomNumber, 
        _id: { $ne: roomIdToUpdate } 
      });

      if (existingRoom) {
        res.status(409).json({ message: 'Số phòng này đã bị trùng với một phòng khác trong hệ thống!' });
        return;
      }
    }

    const room = await Room.findByIdAndUpdate(roomIdToUpdate, req.body, { new: true });
    if (!room) {
      res.status(404).json({ message: 'Room not found' });
      return;
    }

    if (req.body.specialtyId) {
      const activeAssignment = await RoomAssignment.findOne({ roomId: room._id, status: 'active' });
      if (activeAssignment) {
        await Doctor.findByIdAndUpdate(
          activeAssignment.doctorId,
          { specialtyId: req.body.specialtyId, roomId: room._id }
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

export const deleteRoom = async (req: Request, res: Response): Promise<void> => {
  try {
    const room = await Room.findByIdAndDelete(req.params.id);
    if (!room) {
      res.status(404).json({ message: 'Room not found' });
      return;
    }
    res.status(200).json({ message: 'Room deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};