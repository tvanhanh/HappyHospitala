import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:universal_html/html.dart' as html;     
import '../models/bill_model.dart';

class ReportService {
  /// Hàm xuất danh sách hóa đơn ra file Excel hỗ trợ cả Web, Mobile và Desktop
  static Future<void> exportBillsToExcel(List<BillModel> bills) async {
    try {
      // 1. Khởi tạo một Workbook Excel mới
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Báo cáo Thu ngân'];
      excel.delete('Sheet1'); // Xóa sheet mặc định

      // 2. Tạo kiểu định dạng (Styling) cho Tiêu đề bảng
      CellStyle headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#070412'), 
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),       
        fontFamily: getFontFamily(FontFamily.Arial),
        horizontalAlign: HorizontalAlign.Center,
      );

      // 3. Thêm dòng Tiêu đề cột
      List<CellValue?> headers = [
        TextCellValue("STT"),
        TextCellValue("Mã Hóa Đơn"),
        TextCellValue("Mã Bệnh Nhân"),
        TextCellValue("Tên Bệnh Nhân"),
        TextCellValue("Thời Gian Xuất"),
        TextCellValue("Phương Thức Thanh Toán"),
        TextCellValue("Thành Tiền (VND)"),
        TextCellValue("Trạng Thái")
      ];
      sheetObject.appendRow(headers);

      // Áp dụng style cho hàng tiêu đề
      for (int col = 0; col < headers.length; col++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = headerStyle;
      }

      // 4. Đổ dữ liệu từ danh sách BillModel vào các hàng
      int totalRevenue = 0; // Khởi tạo biến tích lũy tổng tiền

      for (int i = 0; i < bills.length; i++) {
        var b = bills[i];
        
        // Cộng dồn tiền của từng hóa đơn
        totalRevenue += b.finalTotalPrice;
        
        String shortId = b.id != null && b.id!.length > 6 
            ? b.id!.substring(b.id!.length - 6).toUpperCase() 
            : (b.id ?? "N/A").toUpperCase();

        String paymentMethod = b.paymentMethod;
        if (paymentMethod == 'paid' || paymentMethod == 'Tiền mặt') {
          paymentMethod = 'Tiền mặt';
        }

        // Đổ chuẩn dữ liệu theo đúng thứ tự các cột tiêu đề
        List<CellValue?> rowData = [
          IntCellValue(i + 1),                                       
          TextCellValue(shortId),                                     
          TextCellValue(b.patientId),                                 
          TextCellValue(b.patientName),                               
          TextCellValue(b.timeArrived),                               
          TextCellValue(paymentMethod),                               
          IntCellValue(b.finalTotalPrice),                            
          TextCellValue("Đã thu")                                     
        ];
        
        sheetObject.appendRow(rowData);
      }

      // --- 5. THÊM DÒNG TỔNG CỘNG (Sau khi đã duyệt xong toàn bộ danh sách) ---
      List<CellValue?> totalRow = [
        TextCellValue("Tổng cộng"), // Ô đầu tiên hiển thị chữ "Tổng cộng"
        TextCellValue(""),          // Bỏ trống các cột giữa
        TextCellValue(""),          
        TextCellValue(""),          
        TextCellValue(""),          
        TextCellValue(""),          
        IntCellValue(totalRevenue), // Đổ tổng số tiền thu được vào đúng cột "Thành Tiền (VND)"
        TextCellValue("")           // Cột Trạng Thái để trống
      ];
      sheetObject.appendRow(totalRow);

      // Định dạng chữ nổi bật cho dòng Tổng cộng
      CellStyle totalStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#070412'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );
      
      int lastRowIndex = sheetObject.maxRows - 1;
      for (int col = 0; col < totalRow.length; col++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: lastRowIndex));
        cell.cellStyle = totalStyle;
      }

      // Tên file báo cáo định dạng theo thời gian
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = "Bao_Cao_Thu_Ngan_$timestamp.xlsx";

      // 6. Mã hóa workbook thành mảng bytes dữ liệu
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) return;

      // 7. PHÂN TÁCH LOGIC LƯU FILE THEO NỀN TẢNG (WEB vs APP)
      if (kIsWeb) {
        // --- XỬ LÝ CHO NỀN TẢNG WEB ---
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click(); 
        
        html.Url.revokeObjectUrl(url);
        print("🌐 Đã tải file báo cáo xuống qua trình duyệt Web thành công!");
        
      } else {
        // --- XỬ LÝ CHO NỀN TẢNG MOBILE/DESKTOP ---
        Directory? outputDir;
        if (Platform.isAndroid || Platform.isIOS) {
          outputDir = await getApplicationDocumentsDirectory();
        } else {
          outputDir = await getDownloadsDirectory(); 
        }

        String filePath = "${outputDir!.path}/$fileName";

        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        print("💾 Đã lưu file báo cáo tại bộ nhớ thiết bị: $filePath");

        await OpenFilex.open(filePath);
      }
    } catch (e) {
      print("💥 Lỗi trong quá trình xuất báo cáo Excel: $e");
      throw Exception("Không thể xuất file Excel: $e");
    }
  }
}