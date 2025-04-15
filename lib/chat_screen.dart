import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.rideId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _chatService.sendMessage(widget.rideId, message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUserName}'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                message['senderName'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              message['message'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
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