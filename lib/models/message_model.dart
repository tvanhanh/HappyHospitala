class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isMe; // Đánh dấu tin nhắn do chính user hiện tại gửi
  final String roomId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.isMe,
    required this.roomId,
  });

  // Chuyển đổi dữ liệu từ JSON (khi gọi API từ Backend về)
  factory MessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final String senderId = json['senderId'] is String
        ? json['senderId'] as String
        : json['senderId'] is Map<String, dynamic>
            ? (json['senderId'] as Map<String, dynamic>)['_id']?.toString() ?? ''
            : json['sender'] is Map<String, dynamic>
                ? (json['sender'] as Map<String, dynamic>)['_id']?.toString() ?? ''
                : json['senderId']?.toString() ?? '';

    final String timestampValue = json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '';
    final DateTime timestamp = timestampValue.isNotEmpty
        ? DateTime.tryParse(timestampValue) ?? DateTime.now()
        : DateTime.now();

    final String? imageUrl = json['imageUrl']?.toString() ?? json['fileUrl']?.toString();

    return MessageModel(
      id: json['_id']?.toString() ?? '',
      senderId: senderId,
      text: json['text'] ?? '',
      imageUrl: imageUrl,
      timestamp: timestamp,
      isMe: senderId == currentUserId,
      roomId: json['roomId']?.toString() ?? '',
    );
  }

  // Chuyển đổi sang JSON để gửi lên Backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'roomId': roomId,
    };
  }

  // Hàm sao chép tạo đối tượng mới (Dùng cho quản lý trạng thái Riverpod)
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isMe,
    String? roomId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      roomId: roomId ?? this.roomId,
    );
  }
}