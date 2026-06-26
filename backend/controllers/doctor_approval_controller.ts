import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import mongoose from 'mongoose';
import User from '../models/User';
import Doctor from '../models/Doctor';

// 1. POST /api/v1/admin/doctors (Role: Admin)
export const createHiddenDoctor = async (req: Request, res: Response) => {
  try {
    const { email, name, password, phone } = req.body;
    const fullName = name;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ message: 'User with this email already exists' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password || '123456', 10);

    // Create User credentials
    const newUser = new User({
      fullName,
      email,
      password: hashedPassword,
      role: 'doctor',
      status: 'activity', // User is active, but doctor profile is hidden
      phoneNumber: phone || '',
    });

    await newUser.save();

    // Create an empty DoctorProfile with profile_status = HIDDEN
    const newDoctorProfile = new Doctor({
      userId: newUser._id,
      profile_status: 'HIDDEN',
    });

    await newDoctorProfile.save();

    res.status(201).json({
      message: 'Doctor account created successfully (HIDDEN)',
      user: newUser,
      doctorProfile: newDoctorProfile
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// GET /api/v1/doctor/profile (Role: Doctor)
export const getOwnDoctorProfile = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    let doctorProfile = await Doctor.findOne({ userId }).populate('specialtyId');
    
    // Auto-create an empty profile if not found for legacy users
    if (!doctorProfile) {
      doctorProfile = new Doctor({
        userId,
        profile_status: 'HIDDEN',
        education: [],
        certifications_urls: []
      });
      await doctorProfile.save();
    }
    const user = await User.findById(userId);
    const result = {
      ...doctorProfile.toObject(),
      avatar: user?.avatar || '',
      fullName: user?.fullName || '',
      phoneNumber: user?.phoneNumber || '',
    };
    
    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// 2. PUT /api/v1/doctor/profile (Role: Doctor)
export const updateDoctorProfileAndSubmit = async (req: Request, res: Response) => {
  try {
    const { bio, experience_years, certifications_urls, avatar_url, specialty, education, consultationFee, phoneNumber } = req.body;
    
    // Assume req.user is set by auth middleware
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    let doctorProfile = await Doctor.findOne({ userId });
    if (!doctorProfile) {
      doctorProfile = new Doctor({
        userId,
        profile_status: 'HIDDEN',
        education: [],
        certifications_urls: []
      });
    }

    // Update fields
    if (bio !== undefined) doctorProfile.bio = bio;
    if (experience_years !== undefined) doctorProfile.experience_years = experience_years;
    if (certifications_urls !== undefined) doctorProfile.certifications_urls = certifications_urls;
    if (specialty !== undefined) doctorProfile.specialty = specialty;
    if (education !== undefined && Array.isArray(education)) doctorProfile.education = education;
    if (consultationFee !== undefined) doctorProfile.consultationFee = consultationFee;
    
    if (avatar_url || phoneNumber !== undefined) {
      const updateData: any = {};
      if (avatar_url) updateData.avatar = avatar_url;
      if (phoneNumber !== undefined) updateData.phoneNumber = phoneNumber;
      await User.findByIdAndUpdate(userId, updateData);
    }

    // Logic: If update is successful, automatically set profile_status = PENDING_APPROVAL
    doctorProfile.profile_status = 'PENDING_APPROVAL';

    await doctorProfile.save();

    res.status(200).json({
      message: 'Profile updated and submitted for approval',
      doctorProfile
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// 3. PUT /api/v1/admin/doctors/:id/status (Role: Admin)
export const reviewDoctorProfile = async (req: Request, res: Response) => {
  try {
    const { id } = req.params; // This is the Doctor profile ID
    const { status, reason } = req.body;

    if (!['ACTIVE', 'REJECTED'].includes(status)) {
      res.status(400).json({ message: 'Invalid status. Must be ACTIVE or REJECTED' });
      return;
    }

    if (status === 'REJECTED' && (!reason || reason.trim() === '')) {
      res.status(400).json({ message: 'Rejection reason is required' });
      return;
    }

    const doctorProfile = await Doctor.findById(id);
    if (!doctorProfile) {
      res.status(404).json({ message: 'Doctor profile not found' });
      return;
    }

    doctorProfile.profile_status = status;
    
    if (status === 'REJECTED') {
      doctorProfile.rejection_reason = reason;
    } else {
      doctorProfile.rejection_reason = ''; // Clear reason if activated
    }

    await doctorProfile.save();

    res.status(200).json({
      message: `Doctor profile status updated to ${status}`,
      doctorProfile
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// 4. GET /api/v1/patients/doctors (Role: Patient/Public)
export const getActiveDoctorsForPatients = async (req: Request, res: Response) => {
  try {
    // Mandatory Filter: WHERE profile_status = 'ACTIVE'
    const activeDoctors = await Doctor.find({ profile_status: 'ACTIVE' })
      .populate('specialtyId', 'name')
      .populate('userId', 'fullName email phoneNumber avatar')
      .lean();

    // Map necessary public fields
    const result = activeDoctors.map(d => {
      const user = d.userId as any;
      return {
        _id: d._id,
        name: user?.fullName,
        email: user?.email,
        phone: user?.phoneNumber,
        avatar: user?.avatar,
        bio: d.bio,
        experience_years: d.experience_years,
        certifications: d.certifications_urls,
        specialtyId: d.specialtyId ? (d.specialtyId as any)._id : null,
        specialty: d.specialtyId ? (d.specialtyId as any).name : null,
        price: d.consultationFee,
      };
    });

    res.status(200).json({
      message: 'Success',
      data: result
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
