import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import 'config.dart';
import '../providers/auth_provider.dart';
import '../models/room_mes_model.dart';

// 1. Khởi tạo AsyncNotifierProvider quản lý danh sách tin nhắn động (Cột giữa)
final chatServiceProvider = AsyncNotifierProvider<MessageService, List<MessageModel>>(() {
  return MessageService();
});

// 2. Khởi tạo StateNotifierProvider quản lý danh sách phòng chat ở cột trái Lễ tân
final chatRoomsProvider = StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<RoomModel>>>((ref) {
  return ChatRoomsNotifier(ref);
});

// ─── CLASS 1: QUẢN LÝ TIN NHẮN TRONG PHÒNG ĐANG CHỌN (CỘT GIỮA) ────────────────
class MessageService extends AsyncNotifier<List<MessageModel>> {
  String? _currentRoomId; // Lưu ID phòng chat lễ tân đang click chọn (chính là ID bệnh nhân)

  String? _getToken() {
    return ref.read(authProvider).token;
  }

  String _getCurrentUserId() {
    return ref.read(authProvider).userId ?? 'guest_user';
  }

  @override
  Future<List<MessageModel>> build() async {
    // Depend on authProvider so that patient chat reloads when login state/userId changes.
    final authState = ref.watch(authProvider);
    if (authState.userId == null || authState.userId!.isEmpty) {
      return [];
    }
    return _fetchMessagesFromAPI();
  }

  /// Hàm kích hoạt đổi phòng dành riêng cho Lễ tân
  Future<void> changeRoom(String roomId) async {
    _currentRoomId = roomId;
    state = const AsyncLoading(); // Hiển thị vòng xoay tải tin nhắn phòng mới
    state = await AsyncValue.guard(() => _fetchMessagesFromAPI());
  }

  // ─── GET: LẤY LỊCH SỬ CHAT TỪ BACKEND ──────────────────────────────────────
  Future<List<MessageModel>> _fetchMessagesFromAPI() async {
    try {
      final token = _getToken();
      final currentUserId = _getCurrentUserId();

      final url = _currentRoomId != null 
          ? '$baseUrl/api/auth/get_messages?roomId=$_currentRoomId'
          : '$baseUrl/api/auth/patient/messages';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> listData = responseData['data'] ?? [];
        
        return listData.map((json) => MessageModel.fromJson(json, currentUserId)).toList();
      } else {
        throw 'Server phản hồi lỗi: ${response.statusCode}';
      }
    } catch (e) {
      throw '💥 Không thể kết nối đến máy chủ: $e';
    }
  }

  // ─── POST: GỬI TIN NHẮN TEXT HOẶC ĐÍNH KÈM TẬP TIN ─────────────────────────
  Future<void> sendMessage({String? text, PlatformFile? pickedFile, String? roomId}) async {
    final previousState = state.value ?? [];
    final currentUserId = _getCurrentUserId();
    final token = _getToken();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/auth/messages'));
      
      request.headers.addAll({
        "Authorization": "Bearer $token",
      });
      
      request.fields['senderId'] = currentUserId;
      
      final String targetRoomId = roomId ?? _currentRoomId ?? currentUserId;
      request.fields['roomId'] = targetRoomId;

      if (text != null && text.trim().isNotEmpty) {
        request.fields['text'] = text.trim();
      }

      if (pickedFile != null && pickedFile.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          pickedFile.bytes!,
          filename: pickedFile.name,
        ));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final serverMessage = MessageModel.fromJson(responseData['data'], currentUserId);
        
        if (targetRoomId == _currentRoomId || _currentRoomId == null) {
          state = AsyncData([...previousState, serverMessage]);
        }

        // Cập nhật nội dung xem trước và đẩy phòng chat lên đầu danh sách (Cột trái)
        ref.read(chatRoomsProvider.notifier).updateLastMessageLocal(
          targetRoomId, 
          text != null && text.trim().isNotEmpty 
              ? text.trim() 
              : (pickedFile != null ? "📁 Tệp: ${pickedFile.name}" : "📷 Đã gửi một hình ảnh")
        );
      } else {
        print('💥 Gửi tin nhắn thất bại: ${response.body}');
      }
    } catch (e, stackTrace) {
      state = AsyncError('Không thể gửi tin nhắn. Vui lòng thử lại!', stackTrace);
    }
  }

  Future<void> pickAndSendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'docx'],
      );

      if (result != null && result.files.single.bytes != null) {
        final pickedFile = result.files.single;
        await sendMessage(pickedFile: pickedFile, roomId: _currentRoomId);
      }
    } catch (e) {
      print('💥 Lỗi chọn tập tin phía Client: $e');
    }
  }

  // ─── PUT: SỬA NỘI DUNG TIN NHẮN ───────────────────────────────────────────
  Future<void> editMessage(String messageId, String newText) async {
    try {
      final token = _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/messages/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"messageId": messageId, "newText": newText}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final updatedMsg = MessageModel.fromJson(responseData['data'], _getCurrentUserId());

        if (state.hasValue) {
          state = AsyncData([
            for (final msg in state.value!)
              if (msg.id == messageId) updatedMsg else msg
          ]);
        }
      }
    } catch (e) {
      print("💥 Lỗi sửa tin nhắn: $e");
    }
  }

  // ─── DELETE: THU HỒI TIN NHẮN ĐƠN LẺ ──────────────────────────────────────
  Future<void> deleteMessage(String messageId) async {
    try {
      final token = _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/messages/delete/$messageId'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        if (state.hasValue) {
          state = AsyncData([
            for (final msg in state.value!)
              if (msg.id != messageId) msg
          ]);
        }
      }
    } catch (e) {
      print("💥 Lỗi xóa tin nhắn: $e");
    }
  }

  // ─── DELETE: XÓA SẠCH LỊCH SỬ CHAT PHÍA BỆNH NHÂN ────────────────────────────
  Future<void> deleteChatForPatient() async {
    try {
      final token = _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/patient/chat'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        state = const AsyncData([]); // Xóa sạch màn hình chat ngay lập tức phía bệnh nhân
      } else {
        print("Lỗi xóa chat: ${response.body}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối khi xóa chat: $e");
    }
  }
}

// ─── CLASS 2: QUẢN LÝ DANH SÁCH TOÀN BỘ PHÒNG CHAT (CỘT TRÁI) ──────────────────
class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  final Ref _ref;
  ChatRoomsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchRoomsFromAPI(); // Tự động lấy danh sách phòng chat khi màn hình lễ tân mở ra
  }

  /// Lấy danh sách tất cả bệnh nhân đang chờ chat
  Future<void> fetchRoomsFromAPI() async {
    try {
      state = const AsyncValue.loading();
      final token = _ref.read(authProvider).token;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/get_chat_rooms'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> listData = responseData['data'] ?? [];
        
        final rooms = listData.map((json) => RoomModel.fromJson(json)).toList();
        state = AsyncValue.data(rooms);
      } else {
        state = AsyncValue.error('Không thể lấy danh sách phòng: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error('💥 Lỗi tải phòng chat: $e', stack);
    }
  }

  /// Hàm bổ trợ cập nhật tin nhắn cuối cùng tại local và đẩy phòng lên đầu danh sách
  void updateLastMessageLocal(String roomId, String text) {
    state.whenData((rooms) {
      List<RoomModel> updatedRooms = [];
      RoomModel? targetedRoom;

      for (final room in rooms) {
        if (room.id == roomId) {
          targetedRoom = RoomModel(
            id: room.id,
            patientName: room.patientName,
            lastMessage: text,
            updatedAt: DateTime.now(), // Cập nhật thời gian mới nhất
            unreadCount: room.unreadCount,
            patientAvatar: room.patientAvatar,
            patientPhone: room.patientPhone,
            patientAge: room.patientAge,
            patientGender: room.patientGender,
            patientStatus: room.patientStatus,
          );
        } else {
          updatedRooms.add(room);
        }
      }

      // Nếu tìm thấy phòng vừa chat, chèn nó lên đầu mảng để giao diện tự đẩy lên top
      if (targetedRoom != null) {
        updatedRooms.insert(0, targetedRoom);
      }

      state = AsyncValue.data(updatedRooms);
    });
  }
}