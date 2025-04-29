import { IUser } from '../models/User'; // Hoặc nơi bạn định nghĩa model User

declare global {
  namespace Express {
    interface Request {
      user?:{
        _id: string,
        email: string,
        role: string,
      }
    }
  }
}

export {};
