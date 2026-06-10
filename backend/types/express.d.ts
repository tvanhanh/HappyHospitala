import { IUser } from '../models/User'; // Hoặc nơi bạn định nghĩa model User

declare global {
  namespace Express {
    interface Request {
      user?:{
        _id: string,
        email: string,
        role: "patient" | "doctor" | "receptionist" | "admin" | "cashier" |"pharmacy";
      }
    }
  }
}

export {};
