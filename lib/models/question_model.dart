class CommentModel {
  final String senderId;
  final String content;
  final DateTime createdAt;

  // Các trường bổ sung nếu backend dùng .populate() trả về thêm thông tin
  final String? senderName;
  final String? senderRole;

  CommentModel({
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.senderRole,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Xử lý thông minh: Nếu senderId là Object (do populate) thì bóc tách ra
    String parsedSenderId = '';
    String? parsedSenderName;
    String? parsedSenderRole;

    if (json['senderId'] is Map) {
      parsedSenderId = json['senderId']['_id']?.toString() ?? '';
      parsedSenderName = json['senderId']['fullName'];
      parsedSenderRole = json['senderId']['role'];
    } else {
      parsedSenderId = json['senderId']?.toString() ?? '';
      // Lấy từ logic mask data của Backend nếu có
      parsedSenderName = json['doctorName'] ?? json['patientName'];
    }

    return CommentModel(
      senderId: parsedSenderId,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      senderName: parsedSenderName,
      senderRole: parsedSenderRole,
    );
  }
}

class QuestionModel {
  final String id;
  final String patientId;
  final String? doctorId;
  final String title;
  final String content;
  final String status;
  final List<String> tags;
  final bool isAnonymous;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Trường bổ sung để hiển thị UI dễ dàng hơn
  final String? patientName;
  final String? patientAvatar;

  QuestionModel({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.title,
    required this.content,
    required this.status,
    required this.tags,
    required this.isAnonymous,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.patientAvatar,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Xử lý thông minh: Nếu patientId là Object (do populate) thì bóc tách ra
    String parsedPatientId = '';
    String? parsedPatientName;
    String? parsedPatientAvatar;

    if (json['patientId'] is Map) {
      parsedPatientId = json['patientId']['_id']?.toString() ?? '';
      parsedPatientName = json['patientId']['fullName'];
      parsedPatientAvatar = json['patientId']['avatar'];
    } else {
      parsedPatientId = json['patientId']?.toString() ?? '';
      parsedPatientName = json['patientName']; // Từ backend mask data
      parsedPatientAvatar = json['patientAvatar'];
    }

    return QuestionModel(
      // MongoDB trả về '_id', map sang 'id' cho Dart dễ dùng
      id: json['_id'] ?? json['id'] ?? '',
      patientId: parsedPatientId,
      doctorId: json['doctorId']?.toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? 'approved',
      // Ép kiểu list động về List<String> an toàn
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      isAnonymous: json['isAnonymous'] ?? true,
      // Map list comments
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      patientName: parsedPatientName ??
          (json['isAnonymous'] == true ? 'Bệnh nhân ẩn danh' : 'Không rõ'),
      patientAvatar: parsedPatientAvatar,
    );
  }
}
