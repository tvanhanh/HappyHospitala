import { Request, Response } from "express";
import MedicalRecord from "../models/medicalRecord";
import User from "../models/User";
import Doctor from "../models/Doctor";
import DiabetesRecord from "../models/medicl_record_infor";
import { generateMedicalPDF } from "../services/pdf.service";
import { calculateHash } from "../services/hash.service";
import { uploadHashToBlockchain } from "../services/blockchain.service";
import fs from "fs";
import { emitToUser } from "../services/socket.service";
import pinataSDK from "@pinata/sdk";
import { getGridFSBucket } from "../config/db";
import { ethers } from "ethers";
import { Contract } from "ethers";
import { getRecordFromBlockchain } from "../services/blockchain.service";
import { wallet } from "../../blockchain/provider";

const pinata = new pinataSDK({ pinataJWTKey: process.env.PINATA_JWT! });

function calculateAge(dob: Date | undefined): number {
  if (!dob) return 30;
  const diff = Date.now() - dob.getTime();
  const ageDate = new Date(diff);
  return Math.abs(ageDate.getUTCFullYear() - 1970);
}

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
    const {
      patientId,
      doctorId,
      symptoms,
      diagnosis,
      treatment,
      metrics,
      visitDate,
    } = req.body ?? {};

    console.log("Dữ liệu nhận từ frontend:", req.body);

    if (!patientId || !doctorId) {
      res.status(400).json({ error: "Missing patientId or doctorId" });
      return;
    }

    // ------------------------------
    // 1. RESOLVE USER & DOCTOR METADATA
    // ------------------------------
    const patientUser = await User.findById(patientId);
    const patientName = patientUser?.fullName || "Bệnh nhân";
    const patientEmail = patientUser?.email || "";
    const gender = patientUser?.gender === "female" ? "Nữ" : "Nam";
    const age = calculateAge(patientUser?.dateOfBirth);

    let doctorName = "Bác sĩ";
    let doctorDoc = await Doctor.findOne({ userId: doctorId });
    if (!doctorDoc) {
      doctorDoc = await Doctor.findById(doctorId);
    }
    if (doctorDoc) {
      const docUser = await User.findById(doctorDoc.userId);
      doctorName = docUser?.fullName || "Bác sĩ";
    } else {
      const docUser = await User.findById(doctorId);
      doctorName = docUser?.fullName || "Bác sĩ";
    }

    // ------------------------------
    // 2. UPLOAD FILES TO GRIDFS (IF PROVIDED VIA MULTIPART)
    // ------------------------------
    const attachmentsId: string[] = [];
    if (req.files && Array.isArray(req.files)) {
      const files = req.files as Express.Multer.File[];
      const gridFSBucket = getGridFSBucket();
      for (const file of files) {
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
    }

    // ------------------------------
    // 3. CREATE DATABASE RECORD
    // ------------------------------
    const record = await MedicalRecord.create({
      patientId,
      doctorId,
      patientName,
      doctorName,
      patientEmail,
      visitDate: visitDate ? new Date(visitDate) : new Date(),
      symptoms: symptoms || "Không ghi nhận triệu chứng",
      diagnosis: diagnosis || "Không mắc bệnh",
      treatment: treatment || "Theo dõi định kỳ, điều chỉnh chế độ ăn uống và sinh hoạt.",
      metrics: metrics || {},
      attachments: attachmentsId, 
    });

    // ------------------------------
    // 4. SYNC TO DIABETES RECORD FOR BACKWARD COMPATIBILITY
    // ------------------------------
    try {
      const d = visitDate ? new Date(visitDate) : new Date();
      const examDateStr = `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
      const examTimeStr = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;

      await DiabetesRecord.create({
        patientId,
        doctorId: doctorDoc?._id || doctorId,
        patientName,
        email: patientEmail,
        examinationDate: examDateStr,
        examinationTime: examTimeStr,
        doctorName,
        departmentName: "Nội tiết",
        gender,
        age: age.toString(),
        urea: metrics?.urea?.toString() || "",
        creatinine: metrics?.creatinine?.toString() || "",
        hba1c: metrics?.hba1c?.toString() || "",
        cholesterol: metrics?.cholesterol?.toString() || "",
        triglycerides: metrics?.triglycerides?.toString() || "",
        hdl: metrics?.hdl?.toString() || "",
        ldl: metrics?.ldl?.toString() || "",
        vldl: metrics?.vldl?.toString() || "",
        bmi: metrics?.bmi?.toString() || "",
        status: diagnosis || "Không mắc bệnh",
      });
      console.log("DiabetesRecord synced successfully");
    } catch (syncErr) {
      console.error("Failed to sync to DiabetesRecord:", syncErr);
    }

    // ------------------------------
    // 5. GENERATE PDF
    // ------------------------------
    const pdfPath = await generateMedicalPDF(record.toObject());

    // ------------------------------
    // 6. UPLOAD PDF TO IPFS
    // ------------------------------
    const ipfsCID  = await uploadPDFToIPFS(pdfPath);
    const ipfsUrl = `https://gateway.pinata.cloud/ipfs/${ipfsCID }`;

    // ------------------------------
    // 7. HASH + BLOCKCHAIN
    // ------------------------------
    const pdfHash = await calculateHash(pdfPath);
    const { txHash, network, blockNumber, blockchainIndex } = await uploadHashToBlockchain(
      patientId,
      ipfsCID,
      pdfHash
    );
   
    console.log("🔥 Blockchain result:", {
      txHash,
      network,
      blockNumber,
    });

    // ------------------------------
    // 8. UPDATE RECORD
    // ------------------------------
    record.pdfUrl = ipfsUrl;
    record.pdfHash = pdfHash;
    record.ipfsHash = ipfsCID ;

    record.blockchainTx = txHash;
    record.blockchainNetwork = network;
    record.blockNumber = blockNumber;
    record.blockchainIndex = blockchainIndex;
    await record.save();

    try { fs.unlinkSync(pdfPath); } catch {}

    // Notify Patient about new medical records / examination result
    if (patientId) {
      emitToUser(patientId.toString(), "new_notification", {
        type: "medical_record_ready",
        title: "Có kết quả khám mới",
        body: `Kết quả khám bệnh của bạn đã sẵn sàng. Bác sĩ điều trị: ${doctorName}. Bạn có thể xem chi tiết trong mục Kết quả.`,
        data: record,
      });
    }

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
// export const searchMedicalRecords = async (req: Request, res: Response) => {
//   const { patientId } = req.query;

//   console.log(" patientId nhận được:", patientId);

//   if (!patientId) {
//      res.status(400).json({ message: "patientId is required" });
//   }

//   const records = await MedicalRecord.find({ patientId }).sort({
//     createdAt: -1,
//   });

//   res.json({ records });
// };
export const searchMedicalRecords = async (req: Request, res: Response) => {
  const { patientId } = req.query;
  console.log(" patientId nhận được:", patientId);
  const records = await MedicalRecord.find({ patientId });

  const result = await Promise.all(
    records.map(async (r) => {
      let isTampered = false;
      console.log("blockchainIndex:",r.blockchainIndex);

      if (typeof r.blockchainIndex === "number") {
        const onChain = await getRecordFromBlockchain(
          r.patientId,
          r.blockchainIndex
        );
        
console.log("⛓️ ON-CHAIN RECORD:", onChain);
        console.log("patientId:",r.patientId);
        console.log("blockchainIndex:",r.blockchainIndex);
        if (onChain && onChain.data !== r.pdfHash) {
          isTampered = true;
        }
      }

      return {
        ...r.toObject(),
        isTampered, // 👈 frontend chỉ cần cái này
      };
    })
  );

  res.json({ records: result });
};