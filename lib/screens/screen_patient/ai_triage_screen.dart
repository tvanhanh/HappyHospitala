import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/config.dart'; // Using the global baseUrl

const Color _kPrimary = Color(0xFF2563EB);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);

class AiTriageScreen extends ConsumerStatefulWidget {
  const AiTriageScreen({super.key});

  @override
  ConsumerState<AiTriageScreen> createState() => _AiTriageScreenState();
}

class _AiTriageScreenState extends ConsumerState<AiTriageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Khởi tạo danh sách tin nhắn theo cấu trúc schema yêu cầu để duy trì lịch sử và metadata.
  // Vòng đời lịch sử trò chuyện được duy trì tại đây.
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'text': 'Chào bạn, tôi là Trợ lý Y tế AI. Bạn đang gặp phải những triệu chứng gì? Hãy mô tả chi tiết (ví dụ: đau đầu, sốt, ho nhiều vào ban đêm) để tôi tư vấn chuyên khoa phù hợp nhé!',
      'specialtyId': null,
      'specialtyName': null,
      'imageUrl': null,
    }
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Load lịch sử chat từ MongoDB để hiển thị lại
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/history'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.clear();
          _messages.addAll(decoded.map((e) => Map<String, dynamic>.from(e)).toList());
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Lỗi load lịch sử chat từ MongoDB: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xóa toàn bộ lịch sử trò chuyện AI Triage trên MongoDB
  void _clearChatHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa lịch sử?'),
          content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử cuộc trò chuyện này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  
                  final response = await http.delete(
                    Uri.parse('$baseUrl/api/ai/history'),
                    headers: {
                      'Content-Type': 'application/json; charset=UTF-8',
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      _messages.clear();
                      _messages.add({
                        'role': 'ai',
                        'text': 'Chào bạn, tôi là Trợ lý Y tế AI. Bạn đang gặp phải những triệu chứng gì? Hãy mô tả chi tiết (ví dụ: đau đầu, sốt, ho nhiều vào ban đêm) để tôi tư vấn chuyên khoa phù hợp nhé!',
                        'specialtyId': null,
                        'specialtyName': null,
                        'imageUrl': null,
                      });
                    });
                    _scrollToBottom();
                  }
                } catch (e) {
                  debugPrint('Lỗi xóa lịch sử chat: $e');
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // Lưu tin nhắn của User tuân thủ đầy đủ schema
      _messages.add({
        'role': 'user', 
        'text': text,
        'specialtyId': null,
        'specialtyName': null,
        'imageUrl': null,
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/triage'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // Gửi toàn bộ danh sách các tin nhắn trước đó làm history để Backend xử lý multi-turn
          'history': _messages.sublist(0, _messages.length - 1),
          'message': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['message'] ?? 'Xin lỗi, tôi chưa hiểu ý bạn.';
        final specialtyId = data['specialtyId'];
        final specialtyName = data['specialtyName'];
        final imageUrl = data['imageUrl'];
        
        setState(() {
          // Lưu tin nhắn phản hồi từ AI kèm theo đầy đủ metadata chuyên khoa
          _messages.add({
            'role': 'ai', 
            'text': aiResponse, 
            'specialtyId': specialtyId,
            'specialtyName': specialtyName,
            'imageUrl': imageUrl,
          });
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMsg = errorData['message'] ?? 'Lỗi không xác định từ server.';
        final detailMsg = errorData['error'] ?? '';
        setState(() {
          _messages.add({
            'role': 'ai', 
            'text': '⚠️ Lỗi: $errorMsg\nChi tiết: $detailMsg',
            'specialtyId': null,
            'specialtyName': null,
            'imageUrl': null,
          });
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai', 
          'text': 'Xin lỗi, hệ thống AI đang gặp lỗi kết nối. Chi tiết: $e',
          'specialtyId': null,
          'specialtyName': null,
          'imageUrl': null,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đợi 100ms để đảm bảo các nút hành động thông minh đã render xong hoàn toàn trước khi cuộn
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Trợ Lý Y Tế AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Xóa lịch sử trò chuyện',
            onPressed: _clearChatHistory,
          ),
        ],
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _kPrimary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _kPrimary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI chỉ đưa ra gợi ý dựa trên triệu chứng, không thay thế chẩn đoán y khoa chính thức.',
                    style: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 16.0),
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology_rounded, size: 16, color: _kPrimary),
                              const SizedBox(width: 6),
                              Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kPrimary)),
                            ],
                          ),
                        if (!isUser) const SizedBox(height: 8),
                        if (msg['imageUrl'] != null && msg['imageUrl'].toString().isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _kPrimary.withValues(alpha: 0.1), width: 2),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    msg['imageUrl'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.medical_services, color: _kPrimary, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg['text']!,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : _kTextPrimary,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            msg['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : _kTextPrimary,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                        // Bong bóng hành động thông minh (Smart Action Buttons) dựa trên kết quả AI phân loại chuyên khoa
                        if (!isUser && index > 0) ...[
                          const SizedBox(height: 12),
                          if (msg['specialtyId'] != null) ...[
                            ElevatedButton.icon(
                              onPressed: () => context.push('/patient/book-appointment/doctors/${msg['specialtyId']}'),
                              icon: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: Text('Đặt lịch khám ${msg['specialtyName'] ?? ""} ngay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => context.push('/chat_support'),
                              icon: const Icon(Icons.support_agent_rounded, size: 16, color: _kPrimary),
                              label: const Text('Trò chuyện trực tiếp với Lễ tân'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _kPrimary, width: 1),
                                foregroundColor: _kPrimary,
                                minimumSize: const Size(double.infinity, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Nhập triệu chứng của bạn...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
