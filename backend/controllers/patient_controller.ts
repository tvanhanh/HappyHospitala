import { Request, Response } from 'express';
import Patient from '../models/Patient';
import User from '../models/User';

export const getPatients = async (req: Request, res: Response) => {
  try {
    const { search } = req.query;

    let query: any = {};
    
    // Find matching users first if search is provided
    if (search && typeof search === 'string') {
      const searchRegex = new RegExp(search, 'i');
      
      // Match by User fields
      const matchingUsers = await User.find({
        role: 'patient',
        $or: [
          { name: searchRegex },
          { 'profile.phone': searchRegex }
        ]
      }).select('_id');
      const userIds = matchingUsers.map(u => u._id);

      // Match by Patient fields
      query = {
        $or: [
          { userId: { $in: userIds } },
          { identityCard: searchRegex }
        ]
      };
    }

    const patients = await Patient.find(query)
      .populate('userId', 'name email profile.phone profile.avatar profile.address')
      .sort({ createdAt: -1 });

    res.status(200).json(patients);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
