
import { Request, Response } from "express";
import MedicalRecord from "../models/medicalRecord";
import { generateMedicalPDF } from "../services/pdf.service";
import { calculateHash } from "../services/hash.service";
import { uploadHashToBlockchain } from "../services/blockchain.service";
import fs from "fs";
import pinataSDK from "@pinata/sdk";
import { getGridFSBucket } from "../config/db";

const pinata = new pinataSDK({ pinataJWTKey: process.env.PINATA_JWT! });

export const uploadPDFToIPFS = async (pdfPath: string) => {
  const fileStream = fs.createReadStream(pdfPath);

  const options = {
    pinataMetadata: {
      name: "medical-record.pdf",
    },
  };

  const result = await pinata.pinFileToIPFS(fileStream, options);
  console.log("Uploaded to IPFS:", result);
  return result.IpfsHash;
};

export const addMedicalRecord = async (req: Request, res: Response) => {
  try {
    const gridFSBucket = getGridFSBucket();
    const files = req.files as Express.Multer.File[];
    console.log("req.files:", req.files);

    const {
      patientId,
      doctorId,
      patientName,
      visitDate,
      symptoms,
      diagnosis,
      treatment,
    
    } = req.body ?? {};

    console.log("Dữ liệu nhận từ frontend:", req.body);
    console.log("Số file:", files?.length);

    if (!patientId || !doctorId) {
      res.status(400).json({ error: "Missing patientId or doctorId" });
      return;
    }

    // ------------------------------
    // 1. UPLOAD FILES TO GRIDFS
    // ------------------------------
    const attachmentsId: string[] = [];

    for (const file of files || []) {
      const uploadStream = gridFSBucket.openUploadStream(
        file.originalname,
        {
          contentType: file.mimetype,
          metadata: {
            patientId,
            doctorId,
          },
        }
      );

      uploadStream.end(file.buffer);

      await new Promise((resolve, reject) => {
        uploadStream.on("finish", () => {
          attachmentsId.push(uploadStream.id.toString());
          resolve(true);
        });
        uploadStream.on("error", reject);
      });
    }

    // ------------------------------
    // 2. CREATE DATABASE RECORD
    // ------------------------------
    const record = await MedicalRecord.create({
      patientId,
      doctorId,
      patientName,
      visitDate: visitDate ? new Date(visitDate) : new Date(),
      symptoms,
      diagnosis,
      treatment,
      attachments: attachmentsId, 
    });

    // ------------------------------
    // 3. GENERATE PDF
    // ------------------------------
    const pdfPath = await generateMedicalPDF(record.toObject());

    // ------------------------------
    // 4. UPLOAD PDF TO IPFS
    // ------------------------------
    const ipfsHash = await uploadPDFToIPFS(pdfPath);
    const ipfsUrl = `https://gateway.pinata.cloud/ipfs/${ipfsHash}`;

    // ------------------------------
    // 5. HASH + BLOCKCHAIN
    // ------------------------------
    const pdfHash = await calculateHash(pdfPath);
    const { txHash, network, blockNumber } = await uploadHashToBlockchain(
      record._id.toString(),
      patientName,
      pdfHash
    );
console.log("🔥 Blockchain result:", {
  txHash,
  network,
  blockNumber,
});

    // ------------------------------
    // 6. UPDATE RECORD
    // ------------------------------
    record.pdfUrl = ipfsUrl;
    record.pdfHash = pdfHash;
    record.ipfsHash = ipfsHash;

    record.blockchainTx = txHash;
    record.blockchainNetwork = network;
    record.blockNumber = blockNumber;
    await record.save();

    try { fs.unlinkSync(pdfPath); } catch {}

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
export const listMedicalRecords = async (req: Request, res: Response) => {
  try {
    const records = await MedicalRecord.find()
      .sort({ createdAt: -1 }) 
      .limit(100);

    res.json({ records });
  } catch (err: any) {
    console.error("Error fetching medical records:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
};
export const getMedicalRecordDetail = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const record = await MedicalRecord.findById(id);

    if (!record) {
       res.status(404).json({
        message: "Không tìm thấy bệnh án",
      });
    }

    res.json({
      record,
    });
  } catch (err: any) {
    console.error("Error fetching medical record detail:", err);
    res.status(500).json({
      error: err.message || "Internal server error",
    });
  }
};
