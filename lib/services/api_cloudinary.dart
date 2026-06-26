import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Thay thế bằng thông tin thực tế trên Dashboard Cloudinary của ông
  static const String cloudName = "ten_cloud_cua_ong";
  static const String uploadPreset = "ten_upload_preset_unsigned_cua_ong";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        // Trả về đường link URL an toàn của tấm ảnh
        return jsonMap['secure_url'];
      } else {
        print("Lỗi upload Cloudinary: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi hệ thống khi upload ảnh: $e");
      return null;
    }
  }
}
