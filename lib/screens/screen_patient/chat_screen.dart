/// Real-time Chat Screen for Patient ↔ Doctor communication.
///
/// [Core-3] Implementation:
/// - Uses [SocketService] for real-time messaging (emit/listen)
/// - Socket events: `send_message`, `receive_message`, `join_room`
/// - Messages are grouped by time and show read receipts
/// - Works in both Web (wide layout) and Mobile (full screen)
/// - Fetches chat history from backend on init
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../services/socket_service.dart';
import '../../services/config.dart';
import '../../providers/booking_provider.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kMine = Color(0xFF1565C0);
const Color _kTheirs = Color(0xFFF0F2F5);
const Color _kBackground = Color(0xFFF0F2F5);

// ══════════════════════════════════════════════════════════════════════════════
// CHAT MESSAGE MODEL
// ══════════════════════════════════════════════════════════════════════════════

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender']?['_id']?.toString() ??
          json['senderId']?.toString() ??
          '',
      senderName: json['sender']?['name']?.toString() ??
          json['senderName']?.toString() ??
          '',
      content: json['content']?.toString() ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  ChatMessage copyWith({bool? isRead}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHAT PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Holds the list of doctors that the patient has had appointments with.
/// Used to populate the chat doctor selection list.
final chatDoctorsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];
    final res = await http.get(
      Uri.parse('$baseUrl/appointments/patient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List appts = (body['data'] ?? body) as List;
      // Extract unique doctors from appointments
      final seen = <String>{};
      final doctors = <Map<String, dynamic>>[];
      for (final a in appts) {
        final doc = a['doctor'];
        if (doc is Map<String, dynamic>) {
          final id = doc['_id']?.toString() ?? '';
          if (id.isNotEmpty && seen.add(id)) {
            doctors.add(doc);
          }
        }
      }
      return doctors;
    }
    return [];
  } catch (_) {
    return [];
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// CHAT LIST SCREEN (Doctor selection)
// ══════════════════════════════════════════════════════════════════════════════

/// Shows a list of doctors the patient can chat with.
///
/// Only doctors with existing appointments are shown (HIPAA-friendly:
/// patients can only chat with their assigned doctors).
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(chatDoctorsProvider);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Nhắn Tin Bác Sĩ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
            tooltip: 'Tìm kiếm',
          ),
        ],
      ),
      body: asyncDoctors.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Không thể tải danh sách',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                onPressed: () => ref.refresh(chatDoctorsProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        data: (doctors) {
          if (doctors.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            itemCount: doctors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (ctx, i) => _DoctorChatTile(doctor: doctors[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 56, color: _kPrimary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có cuộc trò chuyện nào',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Đặt lịch khám để có thể nhắn tin\nvới bác sĩ của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Đặt lịch ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.push('/patient/doctor_list'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorChatTile extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorChatTile({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final profile = (doctor['profile'] as Map<String, dynamic>?) ?? {};
    final name = doctor['name']?.toString() ?? 'Bác sĩ';
    final avatar = profile['avatar']?.toString() ?? '';
    final specialty = profile['specialty']?.toString() ?? '';
    final doctorId = doctor['_id']?.toString() ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: _kPrimary.withOpacity(0.1),
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child:
            avatar.isEmpty ? const Icon(Icons.person, color: _kPrimary) : null,
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        specialty.isNotEmpty ? specialty : 'Bác sĩ phụ trách',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Nhắn tin',
          style: TextStyle(
              color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            doctorId: doctorId,
            doctorName: name,
            doctorAvatar: avatar,
            specialty: specialty,
          ),
        ));
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHAT ROOM SCREEN
// ══════════════════════════════════════════════════════════════════════════════

/// Real-time 1-on-1 chat room between a patient and a doctor.
///
/// [Core-3] Socket.IO implementation:
/// - Joins room `chat:{patientId}:{doctorId}` on open
/// - Emits `send_message` with `{roomId, content, senderId}`
/// - Listens to `receive_message` for incoming messages
/// - Fetches history from `GET /messages/{roomId}` on init
class ChatRoomScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorAvatar;
  final String specialty;

  const ChatRoomScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorAvatar,
    required this.specialty,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false; // Doctor is typing indicator
  String _myId = '';
  String _myName = '';
  String _roomId = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Leave the room when screen closes
    SocketService.instance.emit('leave_room', {'roomId': _roomId});
    SocketService.instance.off('receive_message');
    SocketService.instance.off('typing');
    SocketService.instance.off('stop_typing');
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('userId') ?? '';
    _myName = prefs.getString('name') ?? 'Bệnh nhân';
    _roomId = 'chat:${_myId}_${widget.doctorId}';

    // Join socket room
    SocketService.instance.emit('join_room', {'roomId': _roomId});

    // Listen for incoming messages
    SocketService.instance.on('receive_message', (data) {
      if (!mounted) return;
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    // Typing indicator
    SocketService.instance.on('typing', (_) {
      if (mounted) setState(() => _isTyping = true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isTyping = false);
      });
    });
    SocketService.instance.on('stop_typing', (_) {
      if (mounted) setState(() => _isTyping = false);
    });

    // Fetch message history
    await _loadHistory();

    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom(animate: false);
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('$baseUrl/messages/$_roomId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = (body['data'] ?? body['messages'] ?? []) as List;
        setState(() {
          _messages.addAll(
            raw.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
          );
        });
      }
    } catch (e) {
      // History unavailable — start fresh (non-blocking)
      debugPrint('Chat history fetch error: $e');
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myId,
      senderName: _myName,
      content: content,
      sentAt: DateTime.now(),
    );

    // Optimistic update — add locally immediately
    setState(() => _messages.add(msg));
    _messageController.clear();

    // [Core-3] Emit via Socket.IO
    SocketService.instance.emit('send_message', {
      'roomId': _roomId,
      'content': content,
      'senderId': _myId,
      'senderName': _myName,
      'recipientId': widget.doctorId,
      'sentAt': msg.sentAt.toIso8601String(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent + 100);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary))
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMine = msg.senderId == _myId;
                          final showDate = i == 0 ||
                              !_sameDay(_messages[i - 1].sentAt, msg.sentAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.sentAt),
                              _MessageBubble(message: msg, isMine: isMine),
                            ],
                          );
                        },
                      ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _TypingDot(delay: 0),
                      const _TypingDot(delay: 200),
                      const _TypingDot(delay: 400),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.doctorName} đang nhập...',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: widget.doctorAvatar.isNotEmpty
                ? NetworkImage(widget.doctorAvatar)
                : null,
            child: widget.doctorAvatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isTyping
                      ? 'Đang nhập...'
                      : widget.specialty.isNotEmpty
                          ? widget.specialty
                          : 'Bác sĩ',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined),
          onPressed: () {},
          tooltip: 'Gọi điện (sắp có)',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () {},
          tooltip: 'Thông tin',
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    prefixIcon: IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded,
                          color: Colors.grey.shade400),
                      onPressed: () {}, // Attachment
                    ),
                  ),
                  onChanged: (_) {
                    SocketService.instance.emit('typing', {
                      'roomId': _roomId,
                      'userId': _myId,
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bắt đầu cuộc trò chuyện!',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            'Hỏi bác sĩ về sức khỏe của bạn',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ══════════════════════════════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: _kPrimary.withOpacity(0.1),
                child: const Icon(Icons.person, size: 16, color: _kPrimary),
              ),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? _kMine : _kTheirs,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.sentAt),
                          style: TextStyle(
                            color: isMine
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 12,
                            color: message.isRead
                                ? Colors.blue.shade200
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;
    final label = isToday ? 'Hôm nay' : DateFormat('dd/MM/yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

/// Animated typing dot for the "is typing" indicator.
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
