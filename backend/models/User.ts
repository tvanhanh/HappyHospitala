import mongoose from 'mongoose';

export interface IUser extends mongoose.Document {
  _id: string; 
  name: string;
  phone:string,
  gender: string;
  address: string;
  avatar: string;
  healthInsurance: string;
  email: string;
  password: string;
  role: 'patient' | 'admin' | 'staff' | 'doctor';
  status: 'activity' |'inactive';
  confirmPassword?: string;
  personalData?: any;

}

const userSchema = new mongoose.Schema<IUser>({
  name: { type: String, required: true },
  phone: { type: String },
  gender: { type: String},
  address: { type: String },
  avatar: { type: String },
  healthInsurance: { type: String },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['patient', 'admin', 'staff', 'doctor'], default: 'patient' },
  status: { type: String, enum: ['activity', 'inactive'], default: 'activity' },
  personalData: {
    type: mongoose.Schema.Types.Mixed, // hoặc bạn có thể định nghĩa object rõ ràng hơn nếu muốn
    default: {},
  },
});

userSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.confirmPassword;
    return ret;
  }
});

const User = mongoose.model<IUser>('User', userSchema);
export default User;
