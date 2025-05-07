import 'package:flutter/material.dart';

class PatientDiscussionPage extends StatefulWidget {
  @override
  _PatientDiscussionPageState createState() => _PatientDiscussionPageState();
}

class _PatientDiscussionPageState extends State<PatientDiscussionPage> {
  final List<Map<String, dynamic>> messages = [
    {'sender': 'Bác sĩ', 'text': 'Chào bạn, hôm nay bạn thấy sức khỏe thế nào?'},
    {'sender': 'Bệnh nhân', 'text': 'Dạ em thấy hơi chóng mặt ạ'},
    {'sender': 'Bác sĩ', 'text': 'Bạn có đo huyết áp chưa?'},
  ];

  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        messages.add({'sender': 'Bác sĩ', 'text': text});
        _messageController.clear();
      });
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isDoctor = message['sender'] == 'Bác sĩ';
    return Align(
      alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDoctor ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: isDoctor ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thảo Luận Với Bệnh Nhân'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
