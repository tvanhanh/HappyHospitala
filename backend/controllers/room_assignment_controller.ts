import { Request, Response } from 'express';
import RoomAssignment from '../models/RoomAssignment';
import Room from '../models/Room';
import Doctor from '../models/Doctor';
import SpecialtyRoomDoctor from '../models/SpecialtyRoomDoctor';

export const assignDoctorToRoom = async (req: Request, res: Response) => {
  try {
    const { doctorId, roomId, workingDays, shift } = req.body;
    
    // Deactivate previous active assignments for this doctor to avoid duplicate shifts
    await RoomAssignment.updateMany({ doctorId, status: 'active' }, { status: 'inactive' });
    
    // Remove obsolete SpecialtyRoomDoctor entries for this doctor
    await SpecialtyRoomDoctor.deleteMany({ doctorId });

    const newAssignment = new RoomAssignment({
      doctorId,
      roomId,
      workingDays: workingDays || ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      shift: shift || 'Full',
      status: 'active'
    });

    await newAssignment.save();

    // Fetch Room to see if it is linked to a specialty
    const room = await Room.findById(roomId);
    if (room && room.specialtyId) {
      // Update Doctor specialtyId & roomId
      await Doctor.findByIdAndUpdate(doctorId, {
        roomId: roomId,
        specialtyId: room.specialtyId
      });

      // Upsert to SpecialtyRoomDoctor table
      await SpecialtyRoomDoctor.findOneAndUpdate(
        { specialtyId: room.specialtyId, roomId: roomId, doctorId: doctorId },
        { specialtyId: room.specialtyId, roomId: roomId, doctorId: doctorId },
        { upsert: true, new: true }
      );
    } else {
      // Room has no specialty yet, just update doctor's roomId and unset specialtyId
      await Doctor.findByIdAndUpdate(doctorId, {
        roomId: roomId,
        $unset: { specialtyId: 1 }
      });
    }

    res.status(201).json({ message: "Assigned successfully", assignment: newAssignment });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getRoomAssignments = async (req: Request, res: Response) => {
  try {
    const assignments = await RoomAssignment.find()
      .populate('doctorId', 'doctorName email')
      .populate('roomId', 'roomNumber');
    res.status(200).json(assignments);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const removeAssignment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const assignment = await RoomAssignment.findById(id);
    if (!assignment) {
      return res.status(404).json({ message: "Assignment not found" });
    }

    assignment.status = 'inactive';
    await assignment.save();

    // Delete corresponding SpecialtyRoomDoctor record
    await SpecialtyRoomDoctor.deleteMany({ doctorId: assignment.doctorId, roomId: assignment.roomId });

    // Unset roomId and specialtyId in Doctor model
    await Doctor.findByIdAndUpdate(assignment.doctorId, {
      $unset: { roomId: 1, specialtyId: 1 }
    });

    res.status(200).json({ message: "Assignment removed" });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
