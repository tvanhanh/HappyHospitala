import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart'; 
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

// Đồng bộ hệ màu Premium từ Dashboard sang
const Color kPrimaryColor = Color(0xFF0F172A); 
const Color kSecondaryColor = Color(0xFF2563EB); 
const Color kAccentColor = Color(0xFF10B981); 
const Color kBackgroundColor = Color(0xFFF8FAFC); 
const Color kCardColor = Colors.white;
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextColor = Color(0xFF1E293B);

// ─── WIDGET PHỤ TRỢ: HIỂN THỊ AVATAR VƯỢT LỖI CORS TRÊN FLUTTER WEB ───
class WebNetworkAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const WebNetworkAvatar({
    super.key, 
    required this.imageUrl, 
    this.size = 40.0
  });

  @override
  Widget build(BuildContext context) {
    final String viewId = 'avatar-${imageUrl.hashCode}-${size.toInt()}';

    // Đăng ký thẻ IMG thuần của HTML để bypass cơ chế CORS của trình duyệt Web
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      return html.ImageElement()
        ..src = imageUrl
        ..style.objectFit = 'cover'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '50%';
    });

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: HtmlElementView(viewType: viewId),
    );
  }
}

class ReceptionistMessengerScreen extends ConsumerStatefulWidget {
  const ReceptionistMessengerScreen({super.key});

  @override
  ConsumerState<ReceptionistMessengerScreen> createState() => _ReceptionistMessengerScreenState();
}

class _ReceptionistMessengerScreenState extends ConsumerState<ReceptionistMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedRoomId; 

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Xử lý gửi tin nhắn Text
  void _handleSendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedRoomId == null) return;

    // Bắt buộc truyền kèm _selectedRoomId sang service để biết gửi cho ai
    ref.read(chatServiceProvider.notifier).sendMessage(text: text, roomId: _selectedRoomId!);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. LẮNG NGHE DANH SÁCH CÁC PHÒNG CHAT CỦA BỆNH NHÂN
    final roomsState = ref.watch(chatRoomsProvider);
    
    // 2. LẮNG NGHE DANH SÁCH TIN NHẮN TRONG PHÒNG ĐANG CHỌN
    final chatState = ref.watch(chatServiceProvider);
    final currentRoom = roomsState.maybeWhen(
  data: (rooms) {
    if (rooms.isEmpty || _selectedRoomId == null) return null;
    return rooms.firstWhere((r) => r.id == _selectedRoomId, orElse: () => rooms[0]);
  },
  orElse: () => null,
);
    // ĐÃ SỬA: Sắp xếp điều kiện logic chặt chẽ để tránh vòng lặp set trạng thái vô hạn
    ref.listen(chatRoomsProvider, (previous, next) {
      next.whenData((rooms) {
        if (_selectedRoomId == null && rooms.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedRoomId = rooms[0].id;
            });
            ref.read(chatServiceProvider.notifier).changeRoom(rooms[0].id);
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Trung tâm Hỗ trợ & Chăm sóc khách hàng",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: kBorderColor, height: 1),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: const ReceptionistDrawer(selectedMenu: "Tin nhắn"), 
      body: Row(
        children: [
          // ─── 1. CỘT TRÁI: DANH SÁCH CUỘC HỘI THOẠI (Flex: 2) ───
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: kBorderColor)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm bệnh nhân...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        filled: true,
                        fillColor: kBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: kBorderColor, height: 1),
                  
                  Expanded(
                    child: roomsState.when(
                      data: (rooms) {
                        if (rooms.isEmpty) {
                          return Center(
                            child: Text("Không có cuộc hội thoại nào", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final isSelected = room.id == _selectedRoomId;
                            
                            return InkWell(
                              onTap: () {
                                setState(() => _selectedRoomId = room.id);
                                ref.read(chatServiceProvider.notifier).changeRoom(room.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? kSecondaryColor.withOpacity(0.06) : Colors.white,
                                  border: const Border(top: BorderSide(color: kBorderColor)), 
                                ),
                                child: Row(
                                  children: [
                                    // ĐÃ SỬA: Thay thế ImageNetwork bằng WebNetworkAvatar chống sập CORS
                                    WebNetworkAvatar(
                                      imageUrl: room.patientAvatar ?? 'https://i.pravatar.cc/150?img=33',
                                      size: 40,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  room.patientName,
                                                  style: TextStyle(
                                                    fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: kTextColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('hh:mm A').format(room.updatedAt),
                                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            room.lastMessage,
                                            style: TextStyle(
                                              color: room.unreadCount > 0 ? kTextColor : Colors.grey.shade500,
                                              fontSize: 12,
                                              fontWeight: room.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (room.unreadCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text(
                                          room.unreadCount.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kSecondaryColor)),
                      error: (err, _) => const Center(child: Text("Lỗi tải danh sách")),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 2. CỘT GIỮA: KHUNG CHAT CHI TIẾT (Flex: 4) ───
          Expanded(
            flex: 4,
            child: Container(
              color: kBackgroundColor,
              child: Column(
                children: [
                  // Top Header phòng chat đang chọn
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: kBorderColor)), 
                    ),
                    child: Row(
                      children: [
                        Expanded( // ĐÃ SỬA: Thêm Expanded bảo vệ header không tràn khung
                          child: roomsState.maybeWhen(
                            data: (rooms) {
                              if (rooms.isEmpty || _selectedRoomId == null) return const SizedBox();
                              final currentRoom = rooms.firstWhere((r) => r.id == _selectedRoomId, orElse: () => rooms[0]);
                              return Row(
                                children: [
                                  // ĐÃ SỬA: Thay thế NetworkImage để né lỗi CORS web
                                  WebNetworkAvatar(
                                    imageUrl: currentRoom.patientAvatar ?? 'https://i.pravatar.cc/150?img=33',
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentRoom.patientName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: kAccentColor, shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            Text("Đang kết nối hệ thống", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                            orElse: () => const SizedBox(),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.phone_outlined, size: 20, color: kTextColor), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.videocam_outlined, size: 22, color: kTextColor), onPressed: () {}),
                      ],
                    ),
                  ),

                  // Vùng hiển thị tin nhắn thật từ DB
                  Expanded(
                    child: chatState.when(
                      data: (messages) {
                        _scrollToBottom();
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = currentRoom != null ? (msg.senderId != currentRoom.id) : msg.isMe;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                                    if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: msg.imageUrl!.startsWith('data:image')
                                              ? Image.memory(
                                                  base64Decode(msg.imageUrl!.split('base64,')[1]),
                                                  width: 240, height: 160, fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  msg.imageUrl!,
                                                  width: 240, height: 160, fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),

                                    if (msg.text.isNotEmpty)
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 460),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isMe ? kSecondaryColor : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                          ),
                                          boxShadow: [
                                            if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                                          ],
                                        ),
                                        child: Text(
                                          msg.text,
                                          style: TextStyle(color: isMe ? Colors.white : kTextColor, fontSize: 13, height: 1.4),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('hh:mm a').format(msg.timestamp),
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: kSecondaryColor)),
                      error: (err, _) => const Center(child: Text("Không thể nạp tin nhắn phòng này.")),
                    ),
                  ),

                  // Thanh công cụ nhập nội dung & gửi file của lễ tân
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: kBorderColor)), 
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade400), onPressed: () {}),
                        IconButton(
                          icon: Icon(Icons.image_outlined, color: Colors.grey.shade400), 
                          onPressed: () async {
                            await ref.read(chatServiceProvider.notifier).pickAndSendFile();
                            _scrollToBottom();
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: TextField(
                              controller: _messageController,
                              onSubmitted: (_) => _handleSendTextMessage(),
                              decoration: InputDecoration(
                                hintText: "Nhập tin nhắn hỗ trợ...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: kSecondaryColor),
                          onPressed: _handleSendTextMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. CỘT PHẢI: THÔNG TIN HÀNH CHÍNH (Flex: 2) ───
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: roomsState.maybeWhen(
                data: (rooms) {
                  if (rooms.isEmpty || _selectedRoomId == null) {
                    return const Center(child: Text("Không có hồ sơ bệnh nhân"));
                  }
                  final currentRoom = rooms.firstWhere((r) => r.id == _selectedRoomId, orElse: () => rooms[0]);
                  
                  return SingleChildScrollView( // ĐÃ SỬA: Bọc chống tràn dọc cho cột thông tin hành chính
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // ĐÃ SỬA: Chống lỗi CORS cho ảnh to cột phải
                        WebNetworkAvatar(
                          imageUrl: currentRoom.patientAvatar ?? 'https://i.pravatar.cc/150?img=33',
                          size: 80,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            currentRoom.patientName, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kSecondaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(currentRoom.patientStatus ?? "Bệnh nhân", style: const TextStyle(color: kSecondaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: kBorderColor, height: 1),
                        
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("THÔNG TIN HÀNH CHÍNH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.phone_iphone, "Số điện thoại", currentRoom.patientPhone ?? 'Chưa cập nhật'),
                              _buildInfoRow(Icons.cake_outlined, "Tuổi tác", currentRoom.patientAge ?? 'Chưa rõ'),
                              _buildInfoRow(Icons.wc_rounded, "Giới tính", currentRoom.patientGender ?? 'Nam/Nữ'),
                              const SizedBox(height: 12),
                              const Divider(color: kBorderColor),
                              const SizedBox(height: 12),
                              
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.add_box_outlined, size: 16, color: Colors.white),
                                  label: const Text("Tạo lịch khám nhanh", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
                orElse: () => const Center(child: Text("Đang tải dữ liệu hồ sơ...")),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const Spacer(),
          Expanded( // ĐÃ SỬA: Chống tràn text bên phải khi text hành chính quá dài
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}