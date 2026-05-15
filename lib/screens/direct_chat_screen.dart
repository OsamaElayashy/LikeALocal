import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';

class DirectChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel peerUser;

  const DirectChatScreen({
    super.key,
    required this.chatId,
    required this.peerUser,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _db = DatabaseService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _timeFormat = DateFormat('h:mm a');

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(UserModel currentUser) async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (widget.peerUser.chatPrivacyEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user is in private mode and is not accepting chats.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _db.sendDirectMessage(
        chatId: widget.chatId,
        sender: currentUser,
        receiver: widget.peerUser,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppProvider>().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerUser.name),
        actions: [
          if (widget.peerUser.chatPrivacyEnabled)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.lock_outline, size: 18),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DirectMessage>>(
              stream: _db.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to ${widget.peerUser.name}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = m.senderId == currentUser.id;
                    return _MessageBubble(
                      message: m,
                      isMe: isMe,
                      timeLabel: _timeFormat.format(m.createdAt),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(currentUser),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.peerUser.chatPrivacyEnabled
                        ? null
                        : () => _sendMessage(currentUser),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
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

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;
  final String timeLabel;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isMe ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = isMe ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
