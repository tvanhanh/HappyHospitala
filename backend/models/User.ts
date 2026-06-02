import mongoose from "mongoose";

export interface IUser extends mongoose.Document {
  name: string;
  email: string;
  password: string;

  role: "patient" | "admin" | "staff" | "doctor";
  status: "activity" | "inactive";

  specialization?: string; // doctor

  profile: {
    phone?: string;
    gender?: string;
    address?: string;
    avatar?: string;
    healthInsurance?: string;

    medicalHistory?: string;
    allergies?: string;
    chronicDiseases?: string;

    skinType?: string;
    skinCondition?: string;
    skincareRoutine?: string;

    specialty?: String;

    experience?: String;
    degree?: String;
    description?: String;
    workShift?: String;
    price?: String;
  };

  isDeleted: boolean;
}

const userSchema = new mongoose.Schema<IUser>(
  {
    name: { type: String, required: true },

    email: {
      type: String,
      unique: true,
      required: true,
      lowercase: true,
      trim: true,
    },

    password: { type: String, required: true },

    role: {
      type: String,
      enum: ["patient", "admin", "staff", "doctor"],
      default: "patient",
    },

    status: {
      type: String,
      enum: ["activity", "inactive"],
      default: "activity",
    },

    specialization: String,

    profile: {
      phone: String,
      gender: String,
      address: String,
      avatar: { type: String, default: "" },
      healthInsurance: String,

      medicalHistory: String,
      allergies: String,
      chronicDiseases: String,

      skinType: String,
      skinCondition: String,
      skincareRoutine: String,
      specialty: String,
      experience: String,
      degree: String,
      description: String,
      workShift: String,
      price: String,
    },

    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true },
);

const User = mongoose.model<IUser>("User", userSchema);
export default User;
