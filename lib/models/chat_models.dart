class ChatParticipant {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  factory ChatParticipant.fromMap(String id, Map<String, dynamic> data) {
    return ChatParticipant(
      id: id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}

class DirectMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory DirectMessage.fromMap(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];
    int createdAtMs = 0;
    if (rawCreatedAt is int) {
      createdAtMs = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAtMs = int.tryParse(rawCreatedAt) ?? 0;
    }

    return DirectMessage(
      id: id,
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ChatThread {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatParticipant> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  ChatThread({
    required this.id,
    required this.participantIds,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageAt,
    required this.createdAt,
  });

  ChatParticipant? otherParticipant(String currentUserId) {
    for (final entry in participants.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return null;
  }

  factory ChatThread.fromMap(String id, Map<String, dynamic> data) {
    final rawIds = data['participantIds'];
    final participantIds = <String>[];
    if (rawIds is List) {
      participantIds.addAll(rawIds.map((e) => e.toString()));
    } else if (rawIds is Map) {
      participantIds.addAll(rawIds.values.map((e) => e.toString()));
    }

    final participants = <String, ChatParticipant>{};
    final rawParticipants = data['participants'];
    if (rawParticipants is Map) {
      for (final entry in rawParticipants.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          participants[key] = ChatParticipant.fromMap(
            key,
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    final rawLastMessageAt = data['lastMessageAt'];
    int lastMessageAtMs = 0;
    if (rawLastMessageAt is int) {
      lastMessageAtMs = rawLastMessageAt;
    } else if (rawLastMessageAt is String) {
      lastMessageAtMs = int.tryParse(rawLastMessageAt) ?? 0;
    }

    final rawCreatedAt = data['createdAt'];
    int createdAtMs = 0;
    if (rawCreatedAt is int) {
      createdAtMs = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAtMs = int.tryParse(rawCreatedAt) ?? 0;
    }

    return ChatThread(
      id: id,
      participantIds: participantIds,
      participants: participants,
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastSenderId: data['lastSenderId']?.toString() ?? '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(lastMessageAtMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}
