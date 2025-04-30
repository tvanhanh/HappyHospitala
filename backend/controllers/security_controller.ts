import { Request, Response } from "express";
import Users from "../models/User";


export const getUser = async (req: Request, res: Response) => {
  try {
    const users = await Users.find();
    res.status(200).json(users);
  } catch (error) {
    console.error("Lỗi khi lấy dữ liệuliệu", error);
    res.status(500).json({ message: "Lỗi máy chủ" });
  }
};
export const toggleUserActive = async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const user = await Users.findById(id);
  
      if (!user) {
         res.status(404).json({ message: "Không tìm thấy người dùng" });
         return;
      }
  
      user.status = user.status === 'activity' ? 'activity' : 'inactive'; // Đảo trạng thái active
      await user.save();
  
      res.status(200).json({ message: "Cập nhật trạng thái thành công" });
    } catch (error) {
      console.error("Lỗi khi cập nhật trạng thái người dùng", error);
      res.status(500).json({ message: "Lỗi máy chủ" });
    }
  };
  export const changeUserRole = async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { role } = req.body;
      const validRoles = ['patient', 'staff', 'doctor', 'admin'];
      if (!role || !validRoles.includes(role)) {
         res.status(400).json({ message: "Vai trò không hợp lệ" });
         return;
      }
      const user = await Users.findById(id);
  
      if (!user) {
         res.status(404).json({ message: "Không tìm thấy người dùng" });
         return;
      }
      user.role = role;
      await user.save();
      res.status(200).json({ message: "success" });
       
    } catch (error) {
      console.error("Lỗi khi cập nhật vai trò người dùng", error);
      res.status(500).json({ message: "Lỗi máy chủ" });
    }
  };
    