import mongoose from 'mongoose';

export interface IUser extends mongoose.Document {
  name: string;
  email: string;
  password: string;
  role: 'patient' | 'admin'|'staff'|'doctor';
  confirmPassword?: string;
  personalData?: any;
}

const userSchema = new mongoose.Schema<IUser>({
  name: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['patient', 'admin','staff','doctor'], default: 'patient' },
  personalData: {
    type: mongoose.Schema.Types.Mixed, // hoặc bạn có thể định nghĩa object rõ ràng hơn nếu muốn
    default: {},
  }, // chứa dữ liệu riêng
   
},
);
userSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.confirmPassword;
    return ret;
  }
});

const User = mongoose.model<IUser>('User', userSchema);
export default User;