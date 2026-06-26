import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class MedicalPost {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? patientAvatar;
  final String? doctorId;
  final bool isAnonymous;
  final String title;
  final String content;
  final String status;

  // ĐÃ ĐỔI CHO GIỐNG BACKEND
  final List<String> tags;
  final List<MedicalComment> comments;
  final DateTime createdAt;

  MedicalPost({
    required this.id,
    this.patientId,
    this.patientName,
    this.patientAvatar,
    this.doctorId,
    required this.isAnonymous,
    required this.title,
    required this.content,
    required this.status,
    required this.tags,
    required this.comments,
    required this.createdAt,
  });

  factory MedicalPost.fromJson(Map<String, dynamic> json) {
    // Ép mảng comments từ JSON
    var commentsList = (json['comments'] as List?) ?? [];
    List<MedicalComment> parsedComments = commentsList
        .map((c) => MedicalComment.fromJson(c as Map<String, dynamic>))
        .toList();

    String? pName;
    String? pAvatar;
    if (json['patientId'] is Map) {
      pName = json['patientId']['fullName']?.toString();
      pAvatar = json['patientId']['avatar']?.toString();
    }

    return MedicalPost(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patientId'] is Map
          ? json['patientId']['_id']?.toString()
          : json['patientId']?.toString(),
      patientName: pName,
      patientAvatar: pAvatar,
      doctorId: json['doctorId']?.toString(),
      isAnonymous: json['isAnonymous'] ?? false,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? 'pending',
      // Ép mảng tags từ JSON
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      comments: parsedComments,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
    );
  }
}

// ĐỔI TÊN TỪ MedicalAnswer THÀNH MedicalComment
class MedicalComment {
  // ĐÃ ĐỔI TÊN BIẾN CHO GIỐNG BACKEND
  final String senderId;
  final String senderName;
  final String senderTitle;
  final String content;
  final DateTime createdAt;

  MedicalComment({
    required this.senderId,
    required this.senderName,
    required this.senderTitle,
    required this.content,
    required this.createdAt,
  });

  factory MedicalComment.fromJson(Map<String, dynamic> json) {
    return MedicalComment(
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? json['doctorName'] ?? 'Bác sĩ',
      senderTitle: json['senderTitle'] ?? json['doctorTitle'] ?? 'BS.',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
    );
  }
}

class MedicalQAService {
  // 1. Fetch approved posts (Public/All)
  static Future<List<MedicalPost>> getApprovedPosts(
      {String? specialtyTag}) async {
    // Note: Clean spaces in baseurl if any
    final cleanBaseUrl = baseUrl.replaceAll(' ', '');
    String urlStr = '$cleanBaseUrl/api/qa/posts/approved';
    if (specialtyTag != null && specialtyTag.isNotEmpty) {
      urlStr += '?specialtyTag=${Uri.encodeComponent(specialtyTag)}';
    }

    try {
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => MedicalPost.fromJson(item)).toList();
      } else {
        print('Error fetching approved Q&A posts: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Network error fetching approved Q&A posts: $e');
      return [];
    }
  }

  // 2. Create a new question (Patient only)
  static Future<String?> createQuestion({
    required String token,
    required String title,
    required String content,
    required bool isAnonymous,
    String? specialtyTag,
  }) async {
    final cleanBaseUrl = baseUrl.replaceAll(' ', '');
    final url = Uri.parse('$cleanBaseUrl/api/qa/posts');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'isAnonymous': isAnonymous,
          if (specialtyTag != null) 'specialtyTag': specialtyTag,
        }),
      );

      if (response.statusCode == 201) {
        return null; // success
      } else {
        try {
          final decoded = jsonDecode(response.body);
          return decoded['message'] ?? 'Gửi câu hỏi thất bại';
        } catch (_) {
          return 'Gửi câu hỏi thất bại (Lỗi ${response.statusCode})';
        }
      }
    } catch (e) {
      print('Network error creating Q&A post: $e');
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 3. Submit doctor answer or patient comment
  static Future<String?> submitAnswer({
    required String token,
    required String postId,
    required String responseText,
  }) async {
    final cleanBaseUrl = baseUrl.replaceAll(' ', '');
    final url = Uri.parse('$cleanBaseUrl/api/qa/posts/$postId/comments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': responseText,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // success
      } else {
        try {
          final decoded = jsonDecode(response.body);
          return decoded['message'] ?? 'Gửi bình luận thất bại';
        } catch (_) {
          return 'Gửi bình luận thất bại (Lỗi ${response.statusCode})';
        }
      }
    } catch (e) {
      print('Network error submitting Q&A answer/comment: $e');
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 4. Update post status (Admin only)
  static Future<bool> updatePostStatus({
    required String token,
    required String postId,
    required String status, // 'approved' | 'rejected'
  }) async {
    final cleanBaseUrl = baseUrl.replaceAll(' ', '');
    final url = Uri.parse('$cleanBaseUrl/api/qa/posts/$postId/status');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Network error updating Q&A status: $e');
      return false;
    }
  }

  // 5. Admin: Fetch all Q&A posts (Admin only)
  static Future<List<MedicalPost>> getAllPostsAdmin(
      {required String token}) async {
    final cleanBaseUrl = baseUrl.replaceAll(' ', '');
    final url = Uri.parse('$cleanBaseUrl/api/qa/posts/admin');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => MedicalPost.fromJson(item)).toList();
      } else {
        print('Error fetching admin Q&A posts: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Network error fetching admin Q&A posts: $e');
      return [];
    }
  }
}
