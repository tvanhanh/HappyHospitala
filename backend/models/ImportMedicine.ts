import { Schema, model, Document } from 'mongoose';

const ImportItemSchema = new Schema({
  medicineId: { type: Schema.Types.Mixed, required: true },
  medicineName: { type: String, required: true },
  quantity: { type: Number, required: true },
  importPrice: { type: Number, required: true },
  batchNumber: { type: String, default: null },
  expiryDate: { type: Date, default: null }
  
});

const ImportBillSchema = new Schema({
  supplierId: { type: Schema.Types.Mixed, required: true },
  note: { type: String, default: null },
  totalAmount: { type: Number, required: true },
  products: [ImportItemSchema], 
  status: { type: String, default: 'Chờ duyệt' },
  createdBy: { type: String, default: null }
},

 { timestamps: true });

export const ImportModel = model('ImportMedicine', ImportBillSchema);