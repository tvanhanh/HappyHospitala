import { Request, Response } from 'express';
import Service from '../models/Service';

export const createService = async (req: Request, res: Response): Promise<any> => {
  try {
    const { name, description, duration, price } = req.body;
    const existing = await Service.findOne({ name });
    if (existing) {
      return res.status(400).json({ message: 'Dịch vụ này đã tồn tại!' });
    }
    const service = new Service({ name, description, duration, price });
    const saved = await service.save();
    return res.status(201).json(saved);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
};

export const getServices = async (req: Request, res: Response): Promise<any> => {
  try {
    const services = await Service.find();
    return res.status(200).json(services);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
};

export const getServiceById = async (req: Request, res: Response): Promise<any> => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return res.status(404).json({ message: 'Không tìm thấy dịch vụ!' });
    return res.status(200).json(service);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
};

export const updateService = async (req: Request, res: Response): Promise<any> => {
  try {
    const service = await Service.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!service) return res.status(404).json({ message: 'Không tìm thấy dịch vụ!' });
    return res.status(200).json(service);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
};

export const deleteService = async (req: Request, res: Response): Promise<any> => {
  try {
    const service = await Service.findByIdAndDelete(req.params.id);
    if (!service) return res.status(404).json({ message: 'Không tìm thấy dịch vụ!' });
    return res.status(200).json({ message: 'Xóa dịch vụ thành công!' });
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
};
