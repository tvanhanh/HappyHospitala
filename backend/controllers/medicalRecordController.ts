import { Request, Response } from "express";
import MedicalRecord from "../models/medicalRecord";
import User from "../models/User";
import Doctor from "../models/Doctor";
import DiabetesRecord from "../models/medicl_record_infor";
import { generateMedicalPDF } from "../services/pdf.service";
import { calculateHash } from "../services/hash.service";
import { uploadHashToBlockchain } from "../services/blockchain.service";
import MedicalRecordsABI from "../../blockchain/artifacts/contracts/MedicalRecords.sol/MedicalRecords.json";
import fs from "fs";
import { emitToUser } from "../services/socket.service";
import pinataSDK from "@pinata/sdk";
import { getGridFSBucket } from "../config/db";
import { ethers } from "ethers";
import { Contract } from "ethers";
import { getRecordFromBlockchain } from "../services/blockchain.service";
import { wallet } from "../../blockchain/provider";
import  "../models/AccessRequest";
import axios from "axios";
import crypto from "crypto";
import { AccessRequest } from "../models/AccessRequest";




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
      departmentName,
      doctorName: reqDoctorName,
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

    let doctorName = reqDoctorName || "Bác sĩ";
    let doctorDoc = await Doctor.findOne({ userId: doctorId });
    if (!doctorDoc) {
      doctorDoc = await Doctor.findById(doctorId);
    }
    if (!reqDoctorName) {
      if (doctorDoc) {
        const docUser = await User.findById(doctorDoc.userId);
        doctorName = docUser?.fullName || "Bác sĩ";
      } else {
        const docUser = await User.findById(doctorId);
        doctorName = docUser?.fullName || "Bác sĩ";
      }
    }

    let resolvedDept = departmentName || "Nội tiết";
    if (!departmentName && doctorDoc) {
      if (doctorDoc.specialtyId) {
        const Specialty = require("../models/Specialty").default;
        const spec = await Specialty.findById(doctorDoc.specialtyId);
        if (spec) {
          resolvedDept = spec.name || "Nội tiết";
        }
      } else if (doctorDoc.specialty) {
        resolvedDept = doctorDoc.specialty;
      }
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
    // 3. CREATE DATABASE RECORD
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
      allowedStaffs: [doctorId]
    });

    // ------------------------------
    // 4. SYNC TO DIABETES RECORD FOR BACKWARD COMPATIBILITY
    // ------------------------------
    let syncRecord: any = null;
    try {
      const d = visitDate ? new Date(visitDate) : new Date();
      const examDateStr = `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
      const examTimeStr = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;

      syncRecord = await DiabetesRecord.create({
        patientId,
        doctorId: doctorDoc?._id || doctorId,
        patientName,
        email: patientEmail,
        examinationDate: examDateStr,
        examinationTime: examTimeStr,
        doctorName,
        departmentName: resolvedDept,
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
    // 5. GENERATE PDF
    const pdfPath = await generateMedicalPDF(record.toObject());
    // 6. UPLOAD PDF TO IPFS
    const ipfsCID  = await uploadPDFToIPFS(pdfPath);
    const ipfsUrl = `https://gateway.pinata.cloud/ipfs/${ipfsCID }`;
    // 7. HASH + BLOCKCHAIN
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

    if (syncRecord) {
      try {
        syncRecord.pdfUrl = ipfsUrl;
        syncRecord.pdfHash = pdfHash;
        syncRecord.ipfsHash = ipfsCID;
        syncRecord.blockchainTx = txHash;
        await syncRecord.save();
        console.log("Updated DiabetesRecord with IPFS and Blockchain info successfully");
      } catch (syncUpdateErr) {
        console.error("Failed to update syncRecord with IPFS/blockchain info:", syncUpdateErr);
      }
    }

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
export const getMedicalRecordDetail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params; // id của hồ sơ bệnh án
    const currentUser = req.user; // Lấy từ verifyToken middleware

    if (!currentUser) {
      res.status(401).json({ message: "Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại." });
      return;
    }

    // 1. Tìm hồ sơ bệnh án trước
    const record = await DiabetesRecord.findById(id)
      .populate('patientId')
      .populate({
        path: 'doctorId',
        populate: { path: 'userId' }
      });

    if (!record) {
      res.status(404).json({ message: "Không tìm thấy hồ sơ bệnh án này" });
      return;
    }

    const recordData = record as any;

    // 2. PHÂN QUYỀN TRUY CẬP (Bảo vệ dữ liệu)
    // Trường hợp 1: Nếu người xem chính là bệnh nhân sở hữu hồ sơ này -> Cho phép xem luôn
    const isOwner = recordData.patientId?._id?.toString() === currentUser.id || 
                    recordData.patientId?.toString() === currentUser.id;

    if (!isOwner) {
      // Trường hợp 2: Nếu người xem là Bác sĩ, kiểm tra bảng AccessRequest xem có được duyệt trong 24h không
      const accessCheck = await AccessRequest.findOne({
        doctorId: currentUser.id,
        requestedRecordId: id,
        status: "approved"
      });
      // Nếu không tìm thấy yêu cầu nào được duyệt cho cặp Bác sĩ - Hồ sơ này
      if (!accessCheck) {
        res.status(403).json({ message: "Bạn không có quyền truy cập hoặc chưa được bệnh nhân phê duyệt hồ sơ này." });
        return;
      }
      // Kiểm tra thời gian: Tính khoảng cách từ lúc bệnh nhân bấm "Cho phép" đến hiện tại
      const timeElapsed = Date.now() - new Date(accessCheck.updatedAt).getTime(); 
      const twentyFourHours = 24 * 60 * 60 * 1000; // Quy đổi 24 giờ ra miliseconds
      if (timeElapsed > twentyFourHours) {
        res.status(403).json({ message: "Quyền truy cập hồ sơ này của bạn đã hết hạn (Giới hạn trong vòng 24 giờ)." });
        return;
      }
    }
    // 3. Nếu vượt qua các tầng kiểm tra bảo mật ở trên -> Trả về dữ liệu bệnh án
    res.status(200).json(record);
  } catch (error: any) {
    console.error("❌ Lỗi lấy chi tiết bệnh án:", error);
    res.status(500).json({ message: "Lỗi máy chủ", error: error.message });
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

// Test
export const verifyMedicalRecordIntegrity = async (req: Request, res: Response) => {
  try {
    console.log("req.body:", req.body);
    const { recordId } = req.body;
    
    if (!recordId) {
      res.status(400).json({ error: "Thiếu mã recordId hồ sơ" });
      return;
    }
    // 1. Lấy thông tin từ MongoDB
    const record = await MedicalRecord.findById(recordId);
    if (!record) {
      res.status(404).json({ error: "Không tìm thấy hồ sơ bệnh án trong Database" });
      return;
    }
    // 🛡️ BƯỚC FIX LỖI TS(2345): Kiểm tra nghiêm ngặt dữ liệu trước khi truyền đi
    if (!record.patientId) {
      res.status(400).json({ error: "Hồ sơ bệnh án này thiếu thông tin định danh Bệnh nhân (patientId)" });
      return;
    }
    if (record.blockchainIndex === undefined || record.blockchainIndex === null) {
      res.status(400).json({ error: "Hồ sơ này chưa được neo (anchor) hoặc thiếu chỉ mục trên Blockchain" });
      return;
    }
    // 2. Gọi hàm Blockchain (Lúc này TypeScript sẽ hiểu 'record.patientId' chắc chắn là string, không lo bị undefined)
    const blockchainData = await getRecordFromBlockchain(
      record.patientId, 
      Number(record.blockchainIndex) // Đảm bảo chuyển về kiểu 'number' nguyên bản
    );
    if (!blockchainData) {
      res.status(404).json({ error: "Không tìm thấy dữ liệu tương ứng trên Blockchain" });
      return;
    }
    const blockchainHash = blockchainData.data; // Lấy pdfHash từ blockchain về
    // 3. Tải tệp từ IPFS và tính toán đối chiếu như cũ...
    const ipfsResponse = await axios.get(record.pdfUrl!, { responseType: "arraybuffer" }); // Dấu '!' báo hiệu pdfUrl chắc chắn có
    const pdfBuffer = Buffer.from(ipfsResponse.data);
    const computedHash = "0x" + crypto.createHash("sha256").update(pdfBuffer).digest('hex');
    const isVerifiedSuccess = (computedHash.toLowerCase() === blockchainHash.toLowerCase());
    res.status(200).json({
      ok: true,
      isVerifiedSuccess,
      blockchainHash,
      computedHash,
      blockNumber: record.blockNumber
    });

  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const requestAccess = async (req: Request, res: Response) => {
  try {
    const { recordId, reason, } = req.body; 
    const currentUserId = req.user?.id;
    
    if (!currentUserId) {
      res.status(401).json({ error: "Vui lòng đăng nhập để thực hiện" });
      return;
    }

    const record = await MedicalRecord.findById(recordId);
    if (!record) {
      res.status(404).json({ error: "Không tìm thấy hồ sơ bệnh án" });
      return;
    }

    // Nếu đã có quyền rồi thì không cần xin nữa
    if (record.allowedStaffs.includes(currentUserId)) {
      res.status(400).json({ error: "Bạn đã có quyền truy cập hồ sơ này từ trước." });
      return;
    }

    // Nếu đã nằm trong danh sách chờ rồi thì không push trùng
    if (record.pendingRequests.includes(currentUserId)) {
      res.status(400).json({ error: "Yêu cầu của bạn đang trong trạng thái chờ Bệnh nhân phê duyệt." });
      return;
    }

    // 1. Thêm ID người xin vào mảng chờ trực tiếp trên Medical Record
    record.pendingRequests.push(currentUserId);
    await record.save();

    // 2. 🔑 ĐỒNG BỘ: Tạo song song bản ghi Lịch sử vào bảng AccessRequest để quản lý trạng thái
    const requestId = `REQ-${Date.now()}`; // Tạo mã định danh duy nhất cho request
    
    const newAccessReq = new AccessRequest({
      requestId,
      patientId: record.patientId,
      patientName: record.patientName || "Bệnh nhân",
      doctorId: currentUserId,
      requestedRecordId: recordId,
      reason: reason || "Yêu cầu kiểm tra chéo dữ liệu bệnh án hệ thống.",
      status: "pending",
      time: new Date().toLocaleTimeString('vi-VN') + " " + new Date().toLocaleDateString('vi-VN')
    });
    await newAccessReq.save();

    res.status(200).json({ 
      ok: true, 
      message: "Gửi yêu cầu xin quyền thành công! Vui lòng đợi bệnh nhân phê duyệt.",
      data: newAccessReq // Trả data về để Flutter nạp trực tiếp vào mảng State
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const approveAccessRequest = async (req: Request, res: Response) => {
  try {
    // 🔑 Thêm status vào body để xử lý cả từ chối trực tiếp
    const { recordId, staffId, status = "approved" } = req.body; 
    
    const currentUserId = req.user?.id; 

    const record = await MedicalRecord.findById(recordId);
    if (!record) {
      res.status(404).json({ error: "Không tìm thấy hồ sơ bệnh án" });
      return;
    }

    // Bảo mật: So sánh ID người dùng hiện tại với ID bệnh nhân của hồ sơ
    if (record.patientId.toString() !== currentUserId?.toString()) {
      res.status(403).json({ error: "Bạn không phải chủ sở hữu hồ sơ này nên không thể phê duyệt!" });
      return;
    }

    // Kiểm tra xem bác sĩ này có thực sự nằm trong danh sách chờ của hồ sơ này không
    if (!record.pendingRequests.includes(staffId)) {
      res.status(400).json({ error: "Tài khoản bác sĩ này không nằm trong danh sách chờ phê duyệt của hồ sơ." });
      return;
    }

    // 1. Cập nhật trên document MedicalRecord: Xóa khỏi danh sách chờ (Hủy bỏ pending cho cả 2 trường hợp)
    record.pendingRequests = record.pendingRequests.filter(id => id.toString() !== staffId.toString());
    
    // Nếu ĐỒNG Ý thì mới thêm vào allowedStaffs
    if (status === "approved" && !record.allowedStaffs.includes(staffId)) {
      record.allowedStaffs.push(staffId);
    }
    await record.save();

    // 2. Cập nhật trạng thái tương ứng trong bảng lịch sử AccessRequest
    const accessReq = await AccessRequest.findOne({
      patientId: currentUserId,
      doctorId: staffId,
      requestedRecordId: recordId,
      status: "pending"
    });

    if (accessReq) {
      accessReq.status = status; // "approved" hoặc "rejected"
      await accessReq.save();

      // Bắn socket thông báo cho bác sĩ điều trị nhận tin real-time
      if (typeof emitToUser === "function") {
        emitToUser(staffId.toString(), "new_notification", {
          type: "access_request_result",
          title: status === "approved" ? "Yêu cầu được phê duyệt ✅" : "Yêu cầu bị từ chối ❌",
          body: status === "approved" 
            ? `Bệnh nhân đã đồng ý cấp quyền cho bạn xem hồ sơ mã: ${recordId}.`
            : `Bệnh nhân đã từ chối yêu cầu truy cập hồ sơ mã: ${recordId}.`,
          data: accessReq,
        });
      }
    }

    res.status(200).json({ 
      ok: true, 
      message: status === "approved" ? "Bạn đã phê duyệt cấp quyền thành công!" : "Đã từ chối cấp quyền thành công!" 
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const respondToAccessRequest = async (req: Request, res: Response): Promise<void> => {
  try {
    const { requestId, status } = req.body; // status: "approved" hoặc "rejected"

    // 1. Tìm yêu cầu truy cập dựa vào requestId
    const accessReq = await AccessRequest.findOne({ requestId });
    if (!accessReq) {
      res.status(404).json({ error: "Không tìm thấy yêu cầu" });
      return;
    }

    // 2. Cập nhật trạng thái và tính toán thời gian hết hạn 24h nếu được phê duyệt
    accessReq.status = status;
    if (status === "approved") {
      // Thiết lập thời gian hết hạn = Hiện tại + 24 giờ
      accessReq.createdAt = new Date(); // Đảm bảo mốc thời gian tính từ lúc bấm duyệt
      // Nếu bạn muốn lưu trường expireAt riêng, có thể gán: (accessReq as any).expireAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    }
    await accessReq.save();

    // 3. Cập nhật quyền trực tiếp vào mảng của MedicalRecord gốc để đồng bộ UI
    const recordId = accessReq.requestedRecordId;
    const doctorId = accessReq.doctorId;

    if (status === "approved") {
      await MedicalRecord.findByIdAndUpdate(recordId, {
        $addToSet: { allowedStaffs: doctorId }, // Thêm bác sĩ vào mảng cho phép
        $pull: { pendingRequests: doctorId }    // Xóa khỏi mảng chờ
      });
    } else if (status === "rejected") {
      await MedicalRecord.findByIdAndUpdate(recordId, {
        $pull: { pendingRequests: doctorId }    // Nếu từ chối, chỉ xóa khỏi mảng chờ
      });
    }

    // 4. BẮN NOTIFICATION REAL-TIME BÁO LẠI CHO BÁC SĨ BIẾT KẾT QUẢ
    // @ts-ignore (Bỏ qua check nếu emitToUser khai báo global)
    emitToUser(accessReq.doctorId.toString(), "new_notification", {
      type: "access_request_result",
      title: status === "approved" ? "Yêu cầu được phê duyệt ✅" : "Yêu cầu bị từ chối ❌",
      body: `Bệnh nhân đã ${status === "approved" ? "đồng ý cho bạn xem hồ sơ trong 24 giờ." : "từ chối yêu cầu của bạn."}`,
      data: accessReq,
    });

    res.status(200).json({ ok: true, request: accessReq });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const viewMedicalRecordPdf = async (req: Request, res: Response) => {
  try {
  const { recordId } = req.params;
    const currentUserId = req.user?.id;
    if (!currentUserId) {
      res.status(401).json({ error: "Yêu cầu xác thực! Vui lòng đăng nhập lại." });
      return;
    }
    
    // 1. Tìm hồ sơ bệnh án
    const record = await MedicalRecord.findById(recordId);
    if (!record) {
      res.status(404).json({ error: "Không tìm thấy hồ sơ bệnh án" });
      return;
    }

    const isOwner = record.patientId.toString() === currentUserId;
    let isAuthorized = record.allowedStaffs?.includes(currentUserId); // Mảng chứa ID các bác sĩ được phép

    // 🎯 THÊM LOGIC KIỂM TRA BẢNG ACCESS REQUEST TẠI ĐÂY
    // Nếu chưa được phân quyền trong mảng allowedStaffs, check xem có yêu cầu nào đã duyệt không
    if (!isOwner && !isAuthorized) {
      const approvedRequest = await AccessRequest.findOne({
        requestedRecordId: recordId,
        doctorId: currentUserId,
        status: "approved" // Hoặc "completed" tùy thuộc vào text lưu dưới DB của bạn
      });

      if (approvedRequest) {
        isAuthorized = true; // Hợp lệ! Đánh dấu chuẩn quyền truy cập
      }
    }

    // Kiểm tra lại lần cuối sau khi đã quét cả 2 bảng
    if (!isOwner && !isAuthorized) {
      res.status(403).json({ 
        error: "Truy cập bị từ chối! Bạn chưa nhận được sự cho phép từ bệnh nhân này để xem tài liệu gốc." 
      });
      return;
    }

    if (!record.pdfUrl) {
      res.status(404).json({ error: "Hồ sơ này không đính kèm file PDF gốc" });
      return;
    }

    // 3. Tải file từ IPFS bảo mật thông qua Gateway và Stream trực tiếp về cho client
    const response = await axios({
      method: 'get',
      url: record.pdfUrl,
      responseType: 'stream'
    });

    // Thiết lập Header để trình duyệt hoặc ứng dụng hiểu đây là file PDF
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="medical_record_${recordId}.pdf"`);
    
    // Pipe luồng dữ liệu từ IPFS về thẳng ứng dụng Flutter
    response.data.pipe(res);

  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const getMedicalRecordDetailForDoctor = async (req: Request, res: Response) => {
  try {
    const { recordId, doctorId } = req.query;

    const record = await MedicalRecord.findById(recordId);
    if (!record) {
      res.status(404).json({ error: "Hồ sơ không tồn tại" });
      return;
    }

    // NẾU người đang xem KHÔNG phải bác sĩ điều trị gốc của ca khám này, bắt buộc phải check Consent (sự đồng ý)
    if (record.doctorId.toString() !== doctorId?.toString()) {
      
      const isApproved = await AccessRequest.findOne({
        patientId: record.patientId,
        doctorId: doctorId,
        requestedRecordId: recordId,
        status: "approved" // Chỉ chấp nhận trạng thái đã phê duyệt
      });

      if (!isApproved) {
        res.status(403).json({
          ok: false,
          error: "ACCESS_DENIED",
          message: "Quyền truy cập bị chặn! Bạn cần gửi yêu cầu xác thực và đợi bệnh nhân phê duyệt."
        });
        return;
      }
    }

    // Nếu vượt qua kiểm tra bảo mật thành công -> Trả về dữ liệu chi tiết
    res.status(200).json({ ok: true, data: record });

  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};
export const getDoctorAccessRequestsHistory = async (req: Request, res: Response) => {
  try {
    const currentUserId = req.user?.id;
    
    if (!currentUserId) {
      res.status(401).json({ error: "Yêu cầu xác thực! Vui lòng đăng nhập lại." });
      return;
    }

    // Lấy dữ liệu từ database
    const history = await AccessRequest.find({ doctorId: currentUserId })
      .sort({ createdAt: -1 });

    // Định dạng lại cấu trúc mảng cho khớp với Flutter UI mà không bị ép kiểu lỗi
    const formattedHistory = history.map(item => {
      // 🔑 Ép kiểu sang 'any' tạm thời hoặc bóc tách dữ liệu thuần (lean) từ mongoose document
      const rawData = item.toObject() as any; 

      // Tự động chuyển đổi trường 'createdAt' (đang có sẵn trong Schema) thành chuỗi giờ giấc
      let displayTime = "Vừa xong";
      if (rawData.createdAt) {
        const dateObj = new Date(rawData.createdAt);
        displayTime = dateObj.toLocaleTimeString('vi-VN') + " " + dateObj.toLocaleDateString('vi-VN');
      }

      return {
        id: rawData.requestId,
        status: rawData.status === "pending" ? "Chờ xác nhận" : (rawData.status === "approved" ? "Đã duyệt" : "Bị từ chối"),
        patientName: rawData.patientName || "Bệnh nhân (Hệ thống)", // Tránh lỗi crash nếu schema thiếu trường
        patientId: rawData.patientId,
        reason: rawData.reason,
        time: displayTime, // Sử dụng chuỗi thời gian vừa bóc tách an toàn ở trên
        records: [rawData.requestedRecordId]
      };
    });

    res.status(200).json({ 
      ok: true, 
      data: formattedHistory 
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
};