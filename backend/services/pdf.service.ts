import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import { getImageBufferFromGridFS } from "./gridfs.service";

function formatDate(dateInput: any): string {
  if (!dateInput) return "N/A";
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return "N/A";
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const year = date.getFullYear();
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${day}/${month}/${year} ${hours}:${minutes}`;
}

export async function generateMedicalPDF(record: any): Promise<string> {
  return new Promise(async (resolve, reject) => {
    try {
      const outDir = path.resolve(process.cwd(), "tmp_pdf");
      if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

      const fileName = `medical_record_${record._id || Date.now()}.pdf`;
      const filePath = path.join(outDir, fileName);

      const doc = new PDFDocument({ 
        size: "A4", 
        margin: 50, 
        bufferPages: true 
      });
      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // ========== CẤU HÌNH FONT ==========
      const fontPath = path.join(__dirname, "..", "..", "assets", "fonts", "Roboto-Regular.ttf");
      if (fs.existsSync(fontPath)) {
        doc.registerFont("Roboto", fontPath);
        doc.font("Roboto");
      }

      // ========== 1. HEADER (CẬP NHẬT THÊM THỜI GIAN) ==========
  // ========== 1. HEADER (LOGO NHỎ & BO TRÒN) ==========
      const logoPath = path.join(__dirname, "..", "..", "assets", "logo.png");
      if (fs.existsSync(logoPath)) {
        // 1. Điều chỉnh kích thước nhỏ hơn (Ví dụ: 45 thay vì 60)
        const logoSize = 45;
        
        // Tính toán vị trí căn giữa
        const logoX = (doc.page.width - logoSize) / 2;
        const logoY = 40; // Vị trí Y tính từ trên xuống

        // 2. Tạo hiệu ứng bo tròn (Clipping Mask)
        doc.save(); // Lưu trạng thái graphic hiện tại

        // Vẽ một hình tròn làm khuôn cắt
        // Tâm X, Tâm Y, Bán kính
        doc.circle(logoX + logoSize / 2, logoY + logoSize / 2, logoSize / 2)
           .clip(); // Lệnh cắt: Mọi thứ vẽ sau lệnh này chỉ hiện trong hình tròn

        // Vẽ ảnh logo vào khuôn
        // Sử dụng 'fit' để đảm bảo ảnh vuông vức trong khuôn tròn
        doc.image(logoPath, logoX, logoY, {
          width: logoSize,
          height: logoSize,
          fit: [logoSize, logoSize] 
        });

        doc.restore(); // Khôi phục trạng thái để các phần sau không bị cắt

        // Điều chỉnh khoảng cách xuống dòng sau logo (giảm xuống một chút vì logo nhỏ hơn)
        doc.moveDown(3.5); 
      }

      doc
        .fillColor("#0057B7")
        .fontSize(18)
        .text("HỒ SƠ BỆNH ÁN ĐIỆN TỬ", { align: "center" });
      
      doc
        .fontSize(10)
        .fillColor("#777")
        .text("Hệ thống quản lý y tế Happy Clinic", { align: "center" });

      // THÊM DÒNG THỜI GIAN TẠO FILE TẠI ĐÂY
      doc
        .fontSize(9)
        .fillColor("#999")
        .text(`Thời gian tạo file: ${new Date().toLocaleString("vi-VN")}`, { align: "center" });

      doc.moveDown(1);
      doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor("#eee").stroke();
      doc.moveDown(1.5);

      // ========== 2. THÔNG TIN HÀNH CHÍNH ==========
      doc.fillColor("#0057B7").fontSize(14).text("I. THÔNG TIN HÀNH CHÍNH");
      doc.moveDown(0.5);

      const drawInfoRow = (label: string, value: string) => {
        doc
          .fillColor("#444")
          .fontSize(11)
          .text(label, 70, doc.y, { continued: true }) 
          .fillColor("#000")
          .text(`  ${value || "N/A"}`);
        doc.moveDown(0.4);
      };

      const formatShortId = (id: any, prefix: string) => {
        if (!id) return "N/A";
        const str = id.toString();
        return `${prefix}-${str.slice(-6).toUpperCase()}`;
      };

      drawInfoRow("Họ và tên:", record.patientName?.toUpperCase());
      drawInfoRow("Mã bệnh nhân:", formatShortId(record.patientId, "BN"));
      drawInfoRow("Mã hồ sơ:", formatShortId(record._id, "HS"));
      drawInfoRow("Bác sĩ điều trị:", record.doctorName ? `BS. ${record.doctorName}` : "N/A");
      drawInfoRow("Mã bác sĩ:", formatShortId(record.doctorId, "BS"));
      drawInfoRow("Thời gian khám:", formatDate(record.visitDate || record.createdAt));

      doc.moveDown(1.5);

      // ========== 3. KẾT QUẢ CẬN LÂM SÀNG ==========
      if (doc.y > 650) doc.addPage();
      doc.fillColor("#0057B7").fontSize(14).text("II. KẾT QUẢ CẬN LÂM SÀNG");
      doc.moveDown(0.5);

      const metricsList: { name: string; value: any; unit: string }[] = [];
      if (record.metrics) {
        const rawMetrics = typeof record.metrics.toObject === 'function' ? record.metrics.toObject() : record.metrics;
        const knownMetrics: { [key: string]: { name: string; unit: string } } = {
          hba1c: { name: "Chỉ số HbA1c", unit: "%" },
          urea: { name: "Chỉ số Urea", unit: "mmol/L" },
          creatinine: { name: "Chỉ số Creatinine", unit: "µmol/L" },
          bmi: { name: "Chỉ số BMI", unit: "kg/m²" },
          cholesterol: { name: "Cholesterol toàn phần", unit: "mmol/L" },
          triglycerides: { name: "Triglycerides", unit: "mmol/L" },
          hdl: { name: "HDL-Cholesterol", unit: "mmol/L" },
          ldl: { name: "LDL-Cholesterol", unit: "mmol/L" },
          vldl: { name: "VLDL-Cholesterol", unit: "mmol/L" },
        };
        
        for (const key of Object.keys(rawMetrics)) {
          const value = rawMetrics[key];
          if (value !== undefined && value !== null && String(value).trim() !== "") {
            const lowerKey = key.toLowerCase();
            if (knownMetrics[lowerKey]) {
              metricsList.push({
                name: knownMetrics[lowerKey].name,
                value: value,
                unit: knownMetrics[lowerKey].unit
              });
            } else {
              const formattedKey = key.charAt(0).toUpperCase() + key.slice(1);
              metricsList.push({
                name: formattedKey,
                value: value,
                unit: ""
              });
            }
          }
        }
      }

      if (metricsList.length > 0) {
        const cellWidth = 240;
        const cellHeight = 25;
        const startY = doc.y;
        
        metricsList.forEach((m, index) => {
          const row = Math.floor(index / 2);
          const col = index % 2;
          const x = col === 0 ? 50 : 305;
          const y = startY + row * (cellHeight + 6);
          
          // Draw subtle background card for each metric
          doc.roundedRect(x, y, cellWidth, cellHeight, 4)
             .fillColor("#F8FAFC")
             .fill();
             
          // Draw a small left border strip in primary color to make it look premium
          doc.rect(x, y, 3, cellHeight)
             .fillColor("#0057B7")
             .fill();
          
          // Draw name
          doc.fillColor("#444")
             .fontSize(10)
             .text(m.name, x + 10, y + 7, { width: 140, ellipsis: true });
             
          // Draw value + unit
          const valStr = `${m.value} ${m.unit}`.trim();
          doc.fillColor("#000")
             .fontSize(10)
             .text(valStr, x + 155, y + 7, { width: 80, align: "right" });
        });
        
        const totalRows = Math.ceil(metricsList.length / 2);
        doc.y = startY + totalRows * (cellHeight + 6) + 10;
      } else {
        doc.fillColor("#666").fontSize(11).text("Không có kết quả cận lâm sàng được ghi nhận.", 70, doc.y);
        doc.moveDown(1);
      }

      doc.moveDown(1);

      // ========== 4. NỘI DUNG CHUYÊN MÔN ==========
      if (doc.y > 650) doc.addPage();
      doc.fillColor("#0057B7").fontSize(14).text("III. NỘI DUNG CHUYÊN MÔN");
      doc.moveDown(0.5);

      const drawSection = (title: string, content: string, color: string = "#0057B7") => {
        if (doc.y > 700) doc.addPage();
        doc.moveDown(0.5);
        const currentY = doc.y;
        doc.rect(50, currentY, 3, 18).fill(color);
        doc
          .fillColor(color)
          .fontSize(12)
          .text(title.toUpperCase(), 60, currentY + 3);
        doc.moveDown(0.8);
        doc
          .fillColor("#333")
          .fontSize(11)
          .text(content || "Chưa có nội dung ghi nhận.", 60, doc.y, { 
            align: "justify", 
            lineGap: 2,
            width: 480 
          });
        doc.moveDown(1);
      };

      drawSection("Triệu chứng lâm sàng", record.symptoms);
      drawSection("Chẩn đoán xác định", record.diagnosis, "#E67E22");
      drawSection("Phác đồ điều trị", record.treatment, "#27AE60");

      // ========== 5. HÌNH ẢNH CẬN LÂM SÀNG ==========
      if (record.attachments && record.attachments.length) {
        doc.addPage();
        doc.fillColor("#0057B7").fontSize(14).text("IV. HÌNH ẢNH CẬN LÂM SÀNG", { align: "center" });
        doc.moveDown(1.5);

        let imgY = doc.y;
        for (let i = 0; i < record.attachments.length; i++) {
          try {
            const imgBuffer = await getImageBufferFromGridFS(record.attachments[i]);
            const imgWidth = 320;
            doc.image(imgBuffer, (doc.page.width - imgWidth) / 2, imgY, { fit: [imgWidth, 320] });
            imgY = doc.y + 30;
            if (imgY > 650 && i < record.attachments.length - 1) {
              doc.addPage();
              imgY = 50;
            }
          } catch (err) {
            doc.fillColor("red").text(`❌ Lỗi tải hình ảnh: ${record.attachments[i]}`);
          }
        }
      }

      if (doc.y > 580) {
        doc.addPage();
      }

      // ========== 5. FOOTER ==========
      const range = doc.bufferedPageRange();
      for (let i = range.start; i < range.start + range.count; i++) {
        doc.switchToPage(i);
        if (i === (range.start + range.count - 1)) {
           const sigY = 680;
           doc.fillColor("#000").fontSize(11).text("BÁC SĨ ĐIỀU TRỊ", 350, sigY, { align: "center" });
           doc.fontSize(10).fillColor("#777").text("(Ký và ghi rõ họ tên)", 350, sigY + 15, { align: "center" });
        }
        doc
          .fontSize(8)
          .fillColor("#aaa")
          .text(
            `Trang ${i + 1} / ${range.count}  |  Xác thực bởi Blockchain: ${record.pdfHash?.substring(0, 20) || record.fileHash?.substring(0, 20) || "SECURED"}`,
            50,
            795,
            { align: "center" }
          );
        doc
          .fontSize(8)
          .fillColor("#bbb")
          .text(
            `System Tracking Code: ${record.patientId || "N/A"} - ${record.doctorId || "N/A"}`,
            50,
            807,
            { align: "center" }
          );
      }

      doc.end();
      stream.on("finish", () => resolve(filePath));
    } catch (err) {
      reject(err);
    }
  });
}