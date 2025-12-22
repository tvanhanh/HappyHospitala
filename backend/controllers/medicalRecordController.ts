// controllers/medicalRecord.controller.ts

import { Request, Response } from "express";
import MedicalRecord from "../models/medicalRecord";
import { uploadToStorage } from "../services/storage.service";
import { generateMedicalPDF } from "../services/pdf.service";
import { calculateHash } from "../services/hash.service";
import { uploadHashToBlockchain } from "../services/blockchain.service";
import fs from "fs";
import 'multer';

export const addMedicalRecord = async (req: Request, res: Response) => {
  try {
    const {
      patientId,
      doctorId,
      visitDate,
      symptoms,
      diagnosis,
      treatment,
      patientName,
      doctorName,
    } = req.body;

    if (!patientId || !doctorId) {
       res.status(400).json({ error: "Missing patientId or doctorId" });
    }

    // ------------------------------
    // 1. UPLOAD ATTACHMENTS
    // ------------------------------
    let attachmentUrls: string[] = [];

    if (req.files && Array.isArray(req.files)) {
      const fileArray = req.files as Express.Multer.File[];

      attachmentUrls = await Promise.all(
        fileArray.map(async (file) => await uploadToStorage(file))
      );
    }

    // ------------------------------
    // 2. CREATE DATABASE RECORD
    // ------------------------------
    const record = await MedicalRecord.create({
      patientId,
      doctorId,
      visitDate: visitDate ? new Date(visitDate) : new Date(),
      symptoms,
      diagnosis,
      treatment,
      attachments: attachmentUrls,
    });

    // ------------------------------
    // 3. PREPARE DATA FOR PDF
    // ------------------------------
    const recordForPdf = {
      ...record.toObject(),
      attachments: attachmentUrls,
      patientName: patientName || undefined,
      doctorName: doctorName || undefined,
    };

    // ------------------------------
    // 4. GENERATE PDF
    // ------------------------------
    const pdfPath = await generateMedicalPDF(recordForPdf);

    // ------------------------------
    // 5. UPLOAD PDF TO STORAGE
    // ------------------------------
    const pdfUrl = await uploadToStorage({
      path: pdfPath,
      originalname: `record-${record._id}.pdf`,
      mimetype: "application/pdf",
    });

    // ------------------------------
    // 6. HASH PDF + UPLOAD TO BLOCKCHAIN
    // ------------------------------
    const pdfHash = await calculateHash(pdfPath);
    const txHash = await uploadHashToBlockchain(record._id.toString(), pdfHash);

    // ------------------------------
    // 7. SAVE UPDATE TO DATABASE
    // ------------------------------
    record.pdfUrl = pdfUrl;
    record.pdfHash = pdfHash;
    record.blockchainTx = txHash;
    await record.save();

    // Clean up
    try {
      fs.unlinkSync(pdfPath);
    } catch {}

     res.status(201).json({
      ok: true,
      message: "Medical record created successfully",
      record,
    });
  } catch (err: any) {
    console.error("Error creating medical record:", err);
     res.status(500).json({
      error: err.message || "Internal server error",
    });
  }
};

// ------------------------------------------------------------
// GET RECORD BY ID
// ------------------------------------------------------------
export const getMedicalRecordById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = (req as any).user;

    const record = await MedicalRecord.findById(id)
      .populate("patientId")
      .populate("doctorId");

    if (!record) {
     res.status(404).json({ error: "Record not found" });
     return;
    }

    // Authorization: patients can only view their own records
    if (
      user.role === "patient" &&
      String(record.patientId._id) !== String(user.userId)
    ) {
       res.status(403).json({ error: "Not allowed" });
    }

     res.json({ record });
     return;
  } catch (err) {
     res.status(500).json({ error: "Internal server error" });
  }
};

// ------------------------------------------------------------
// LIST RECORDS (ADMIN / DOCTOR)
// ------------------------------------------------------------
export const listMedicalRecords = async (req: Request, res: Response) => {
  try {
    const records = await MedicalRecord.find()
      .sort({ createdAt: -1 })
      .limit(100);

    return res.json({ records });
  } catch (err) {
    return res.status(500).json({ error: "Internal server error" });
  }
};
