import { Request, Response } from 'express';
import Specialty from '../models/Specialty';
import Room from '../models/Room';
import RoomAssignment from '../models/RoomAssignment';
import Doctor from '../models/Doctor';
import SpecialtyRoomDoctor from '../models/SpecialtyRoomDoctor';

export const createSpecialty = async (req: Request, res: Response) => {
  try {
    const { name, description, imageUrl, existingRoomIds, newRooms } = req.body;
    
    const specialty = new Specialty({ name, description, imageUrl });
    const savedSpecialty = await specialty.save();

    // 1. Assign existing rooms
    if (existingRoomIds && Array.isArray(existingRoomIds) && existingRoomIds.length > 0) {
      await Room.updateMany(
        { _id: { $in: existingRoomIds } },
        { specialtyId: savedSpecialty._id }
      );

      // Handle SpecialtyRoomDoctor linking and Doctor department updates
      for (const rId of existingRoomIds) {
        const activeAssignment = await RoomAssignment.findOne({ roomId: rId, status: 'active' });
        if (activeAssignment) {
          // Update Doctor specialtyId & roomId
          await Doctor.findByIdAndUpdate(
            activeAssignment.doctorId,
            { specialtyId: savedSpecialty._id, roomId: rId }
          );

          // Save to SpecialtyRoomDoctor table
          await SpecialtyRoomDoctor.findOneAndUpdate(
            { specialtyId: savedSpecialty._id, roomId: rId, doctorId: activeAssignment.doctorId },
            { specialtyId: savedSpecialty._id, roomId: rId, doctorId: activeAssignment.doctorId },
            { upsert: true, new: true }
          );
        }
      }
    }

    // 2. Create new rooms
    if (newRooms && Array.isArray(newRooms) && newRooms.length > 0) {
      const roomDocs = newRooms.map((r: any) => ({
        roomNumber: r.roomNumber,
        floor: r.floor,
        status: 'Available',
        specialtyId: savedSpecialty._id
      }));
      await Room.insertMany(roomDocs);
    }

    res.status(201).json(savedSpecialty);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const getSpecialties = async (req: Request, res: Response) => {
  try {
    const specialties = await Specialty.find();
    res.status(200).json(specialties);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getSpecialtyById = async (req: Request, res: Response) => {
  try {
    const specialty = await Specialty.findById(req.params.id);
    if (!specialty) return res.status(404).json({ message: 'Specialty not found' });
    res.status(200).json(specialty);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateSpecialty = async (req: Request, res: Response) => {
  try {
    const specialty = await Specialty.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!specialty) return res.status(404).json({ message: 'Specialty not found' });
    res.status(200).json(specialty);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteSpecialty = async (req: Request, res: Response) => {
  try {
    const specialty = await Specialty.findByIdAndDelete(req.params.id);
    if (!specialty) return res.status(404).json({ message: 'Specialty not found' });
    res.status(200).json({ message: 'Specialty deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getDoctorsBySpecialty = async (req: Request, res: Response) => {
  try {
    const { specialtyId } = req.params;
    
    // Find the doctors and populate their user details
    const doctors = await Doctor.find({ specialtyId, profile_status: 'ACTIVE' })
      .populate('specialtyId', 'name')
      .populate('userId', 'fullName email phoneNumber avatar')
      .lean();

    const result = doctors.map((d: any) => {
      const user = d.userId as any;
      return {
        _id: d._id,
        name: user?.fullName,
        email: user?.email,
        phone: user?.phoneNumber,
        avatar: user?.avatar,
        specialtyId_id: d.specialtyId ? d.specialtyId._id : null,
        specialty: d.specialtyId ? d.specialtyId.name : null,
        roomId_id: d.roomId ? d.roomId : null,
        experience: d.experience_years ? String(d.experience_years) : '0',
        price: d.consultationFee ? String(d.consultationFee) : '0',
        description: d.bio || '',
      };
    });

    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
