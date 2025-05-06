import 'package:flutter/material.dart';
import '../../services/api_aiService.dart'; // Đường dẫn tùy dự án bạn

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  Future<void> sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": userInput});
      _controller.clear();
    });

    try {
      final reply = await AIService.getRequest(userInput);

      setState(() {
        messages.add({"role": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "⚠️ Lỗi kết nối server"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💬 Chat với AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Nhập câu hỏi...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
