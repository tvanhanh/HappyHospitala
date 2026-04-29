// services/pdf.service.ts
import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import axios from "axios";
import { getImageBufferFromGridFS } from "./gridfs.service";


async function fetchImageBuffer(url: string): Promise<Buffer> {
  const res = await axios.get(url, { responseType: "arraybuffer" });
  return Buffer.from(res.data, "binary");
}

export async function generateMedicalPDF(record: any): Promise<string> {
  return new Promise(async (resolve, reject) => {
    try {
      const outDir = path.resolve(process.cwd(), "tmp_pdf");
      if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

      const fileName = `medical_record_${record._id || Date.now()}.pdf`;
      const filePath = path.join(outDir, fileName);

      const doc = new PDFDocument({ size: "A4", margin: 40 });
      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // ========== FONT ==========
      const fontPath = path.join(__dirname, "..", "assets", "fonts", "Roboto-Regular.ttf");
      if (fs.existsSync(fontPath)) {
        doc.registerFont("Roboto", fontPath);
        doc.font("Roboto");
      }

      // ========== LOGO ==========
      const logoPath = path.join(__dirname, "..", "assets", "logo.png");
      if (fs.existsSync(logoPath)) {
        doc.image(logoPath, 40, 30, { width: 70 });
      }

      // ========== HEADER ==========
      doc
        .fontSize(20)
        .fillColor("#0057B7")
        .text("HỒ SƠ BỆNH ÁN", 0, 40, { align: "center" });

      doc.moveDown(2);

      // ========== THÔNG TIN BỆNH NHÂN ==========
      doc
        .fontSize(13)
        .fillColor("#000")
        .text("📌 Thông tin khám bệnh", { underline: true });

      doc.moveDown(0.5);

      const info = [
        ["Mã bệnh án:", record._id || "N/A"],
        ["Mã bệnh nhân:", record.patientId],
        ["Tên bệnh nhân:", record.patientName],
        ["Bác sĩ:", record.doctorName || record.doctorId],
        [
          "Ngày khám:",
          new Date(record.visitDate || record.createdAt).toLocaleString("vi-VN"),
        ],
      ];

      doc.fontSize(11).fillColor("#333");

      info.forEach(([label, value]) => {
        doc.text(`${label}  ${value}`);
      });

      doc.moveDown(1.2);

      // ========== HÀM TẠO SECTION ==========
      const pushSection = (title: string, content: string) => {
        doc
          .fontSize(14)
          .fillColor("#000")
          .text(title, { underline: true });

        doc.moveDown(0.3);

        doc
          .fontSize(11)
          .fillColor("#333")
          .text(content || "—", { align: "justify" });

        doc.moveDown(1);
      };

      pushSection("Triệu chứng", record.symptoms);
      pushSection("Chẩn đoán", record.diagnosis);
      pushSection("Cách điều trị", record.treatment);

      // ========== HIỂN THỊ HÌNH ẢNH ==========
if (record.attachments && Array.isArray(record.attachments) && record.attachments.length) {
  doc.addPage();

  doc
    .fontSize(14)
    .fillColor("#000")
    .text("📎 Hình ảnh đính kèm", { underline: true });

  doc.moveDown(1);

  for (let i = 0; i < record.attachments.length; i++) {
    const fileId = record.attachments[i];

    try {
      const imgBuffer = await getImageBufferFromGridFS(fileId);

      const x = 40 + (i % 2) * 260;
      const y = doc.y;

      doc.image(imgBuffer, x, y, {
        fit: [240, 240],
        align: "center",
        valign: "center",
      });

      if (i % 2 === 1) doc.moveDown(16);
      if (doc.y > 700) doc.addPage();

    } catch (err) {
      doc
        .fontSize(10)
        .fillColor("red")
        .text(`❌ Không thể tải ảnh: ${fileId}`);
    }
  }
}


      // ========== FOOTER ==========
      doc.addPage();
      doc
        .fontSize(11)
        .fillColor("#555")
        .text("Hồ sơ được tạo bởi hệ thống quản lý bệnh viện", {
          align: "center",
        });
      doc.text(`Ngày tạo PDF: ${new Date().toLocaleString("vi-VN")}`, {
        align: "center",
      });

      doc.end();

      stream.on("finish", () => resolve(filePath));
      stream.on("error", reject);
    } catch (err) {
      reject(err);
    }
  });
}
