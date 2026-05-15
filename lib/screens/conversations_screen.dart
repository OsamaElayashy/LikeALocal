import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import 'direct_chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchController = TextEditingController();
  final _db = DatabaseService();
  final _timeFormat = DateFormat('h:mm a');

  Timer? _debounce;
  bool _isSearching = false;
  List<UserModel> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _searchUsers);
  }

  Future<void> _searchUsers() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    final currentUser = app.currentUser;
    if (currentUser == null) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final users = await _db.searchUsers(
      query: query,
      currentUserId: currentUser.id,
    );

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _results = users;
    });
  }

  Future<void> _openDirectChat(UserModel currentUser, UserModel targetUser) async {
    if (targetUser.chatPrivacyEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user is in private mode and is not accepting chats.'),
        ),
      );
      return;
    }

    final chatId = await _db.ensureDirectChat(
      currentUser: currentUser,
      otherUser: targetUser,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          chatId: chatId,
          peerUser: targetUser,
        ),
      ),
    );
  }

  String _formatChatTime(DateTime when) {
    if (when.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final sameDay = now.year == when.year && now.month == when.month && now.day == when.day;
    if (sameDay) return _timeFormat.format(when);
    return DateFormat('MMM d').format(when);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currentUser = app.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Expanded(
            child: query.isNotEmpty
                ? _buildSearchResults(currentUser, scheme)
                : _buildChatsList(currentUser, scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserModel currentUser, ColorScheme scheme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final user = _results[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              user.initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: user.chatPrivacyEnabled
              ? const Icon(Icons.lock_outline, size: 18)
              : const Icon(Icons.chat_bubble_outline, size: 18),
          onTap: () => _openDirectChat(currentUser, user),
        );
      },
    );
  }

  Widget _buildChatsList(UserModel currentUser, ColorScheme scheme) {
    return StreamBuilder<List<ChatThread>>(
      stream: _db.watchUserChats(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Text(
              'No chats yet. Search someone to start chatting.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final chat = chats[i];
            final other = chat.otherParticipant(currentUser.id);
            if (other == null) return const SizedBox.shrink();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initialsFromName(other.name),
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(other.name),
              subtitle: Text(
                chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatChatTime(chat.lastMessageAt),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              onTap: () async {
                final peer =
                    await _db.getUserData(other.id) ??
                    UserModel(
                      id: other.id,
                      name: other.name,
                      email: other.email,
                      avatarUrl: other.avatarUrl,
                    );
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      chatId: chat.id,
                      peerUser: peer,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}
