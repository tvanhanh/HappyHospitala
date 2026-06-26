import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart'; 

// Đồng bộ hệ màu Premium từ hệ thống SaaS Clinic
const Color kPrimaryColor = Color(0xFF0F172A); 
const Color kSecondaryColor = Color(0xFF2563EB); 
const Color kAccentColor = Color(0xFF10B981); 
const Color kBackgroundColor = Color(0xFFF8FAFC); 
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextColor = Color(0xFF1E293B);

class CustomerMessengerScreen extends ConsumerStatefulWidget {
  const CustomerMessengerScreen({super.key});

  @override
  ConsumerState<CustomerMessengerScreen> createState() => _CustomerMessengerScreenState();
}

class _CustomerMessengerScreenState extends ConsumerState<CustomerMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🌟 SỬA BUG UX: Tự động cuộn xuống dưới cùng một cách an toàn thông qua PostFrameCallback
  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── 1. CHỨC NĂNG: GỬI TIN NHẮN TEXT ────────────────────────────────────────
  Future<void> _handleSendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    await ref.read(chatServiceProvider.notifier).sendMessage(text: text);
    _scrollToBottom();
  }

  // ─── 2. CHỨC NĂNG: GỬI HÌNH ẢNH / TẬP TIN ────────────────────────────────────
  Future<void> _handleSendFile() async {
    await ref.read(chatServiceProvider.notifier).pickAndSendFile();
    _scrollToBottom();
  }

  // ─── 3. CHỨC NĂNG: MENU TÙY CHỌN CHỈNH SỬA / THU HỒI TIN NHẮN ──────────────────
  void _showEditDeleteMenu(BuildContext context, MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  "Tùy chọn tin nhắn",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
              const Divider(height: 1, color: kBorderColor),
              // Chỉ cho phép Sửa nếu tin nhắn đó có text chữ và không chứa hậu tố đã chỉnh sửa trước đó
              if (msg.text.isNotEmpty && !msg.text.contains('(đã chỉnh sửa)'))
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: kSecondaryColor, size: 20),
                  title: const Text('Chỉnh sửa tin nhắn', style: TextStyle(fontSize: 13.5)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, msg);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                title: const Text('Thu hồi tin nhắn', style: TextStyle(fontSize: 13.5, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatServiceProvider.notifier).deleteMessage(msg.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hiển thị ô nhập để cập nhật lại nội dung tin nhắn chữ
  void _showEditDialog(BuildContext context, MessageModel msg) {
    // Loại bỏ chữ mẫu "(đã chỉnh sửa)" nếu có khi hiển thị lên ô nhập liệu
    final cleanText = msg.text.replaceAll(" (đã chỉnh sửa)", "");
    final editController = TextEditingController(text: cleanText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Chỉnh sửa tin nhắn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: "Nhập nội dung mới...",
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != cleanText) {
                ref.read(chatServiceProvider.notifier).editMessage(msg.id, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Cập nhật', style: TextStyle(color: kSecondaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── 4. CHỨC NĂNG: XÓA SẠCH LỊCH SỬ CHAT (ẨN PHÍA LOCAL BỆNH NHÂN) ───────────────
  void _handleDeleteAllChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Xóa lịch sử trò chuyện?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'Toàn bộ tin nhắn sẽ bị ẩn đi khỏi màn hình của bạn. Bạn vẫn có thể nhắn tin mới bất cứ lúc nào.',
          style: TextStyle(fontSize: 13, color: kTextColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatServiceProvider.notifier).deleteChatForPatient();
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final chatState = ref.watch(chatServiceProvider);

    // 🌟 SỬA LỖI: Lắng nghe trạng thái thay đổi dữ liệu tin nhắn để tự động cuộn xuống đáy một cách chủ động
    ref.listen(chatServiceProvider, (previous, next) {
      if (next.hasValue) {
        _scrollToBottom();
      }
    });

    return Align(
      alignment: isWeb ? Alignment.bottomRight : Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(
          right: isWeb ? 24.0 : 0.0,
          bottom: isWeb ? 90.0 : 0.0, 
          left: isWeb ? 0.0 : 16.0,
          top: isWeb ? 0.0 : 16.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 400 : MediaQuery.of(context).size.width * 0.9, 
            maxHeight: isWeb ? 580 : MediaQuery.of(context).size.height * 0.8,
          ),
          child: Material(
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.2),
            color: kBackgroundColor,
            type: MaterialType.canvas,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. HEADER CHAT
                  _buildHeader(context, isWeb),
                  
                  // 2. DANH SÁCH BONG BÓNG TIN NHẮN TRỰC TUYẾN
                  Expanded(
                    child: chatState.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              "Chưa có tin nhắn. Hãy bắt đầu trò chuyện!",
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _buildChatBubble(context, msg);
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: kSecondaryColor, strokeWidth: 2),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "$error",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Ô NHẬP TIN NHẮN VÀ ĐÍNH KÈM FILE
                  _buildChatInput(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWeb) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorderColor)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: kSecondaryColor.withOpacity(0.1),
                child: const Icon(Icons.support_agent_rounded, color: kSecondaryColor, size: 18),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Hỗ trợ Happy Clinic",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
                ),
                Text(
                  "Thường trả lời ngay",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey, size: 18),
            tooltip: "Xóa toàn bộ lịch sử",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _handleDeleteAllChat(context),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: kTextColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, MessageModel msg) {
    final bool isMe = msg.isMe; 
    final String formattedTime = DateFormat('hh:mm a').format(msg.timestamp.toLocal());
    final bool isEdited = msg.text.contains("(đã chỉnh sửa)");

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                if (isMe) {
                  _showEditDeleteMenu(context, msg);
                }
              },
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // KIỂM TRA VÀ HIỂN THỊ HÌNH ẢNH ĐÍNH KÈM
                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: msg.imageUrl!.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(msg.imageUrl!.split('base64,')[1]),
                                width: 200,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                msg.imageUrl!,
                                width: 200,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 200,
                                  height: 140,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),

                  // HIỂN THỊ CHỮ (NẾU CÓ)
                  if (msg.text.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? kSecondaryColor : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                        ),
                        border: isMe ? null : const Border.fromBorderSide(BorderSide(color: kBorderColor)),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : kTextColor,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // HIỂN THỊ THỜI GIAN VÀ TAG TRẠNG THÁI "ĐÃ CHỈNH SỬA" TIN TINH TẾ
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEdited) ...[
                  Text(
                    "Đã chỉnh sửa • ",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontStyle: FontStyle.italic),
                  ),
                ],
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _handleSendFile,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _handleSendTextMessage(),
                style: const TextStyle(fontSize: 12.5),
                decoration: const InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 15,
            backgroundColor: kSecondaryColor,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 12),
              padding: EdgeInsets.zero,
              onPressed: _handleSendTextMessage,
            ),
          ),
        ],
      ),
    );
  }
}