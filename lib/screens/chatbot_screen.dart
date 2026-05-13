import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';
import '../config/api_config.dart';

// Represents one message in the chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false; // shows "LocalBot is typing..."

  // Gemini API key
  static const String _apiKey = geminiApiKey;
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  @override
  void initState() {
    super.initState();
    // Show welcome message when screen opens
    _messages.add(ChatMessage(
      text:
          "Hi! I'm LocalBot 👋\n\nI know all the best places in Cairo, Alexandria, Giza, Luxor, Sharm El Sheikh, and Hurghada.\n\nTell me what you're looking for — a 3-day plan, cozy cafes, hidden gems, budget restaurants — anything!",
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to bottom after new message
  void _scrollToBottom() {
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

  // Build a summary of all places to send to Gemini
  // This is how the AI "knows" about your app's data
  String _buildPlacesContext(List<Place> places) {
    if (places.isEmpty) {
      return 'No places have been added to the app yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Here are all the places in the LikeALocal app:\n');

    // Group by city for better context
    final byCity = <String, List<Place>>{};
    for (final place in places) {
      byCity.putIfAbsent(place.city, () => []).add(place);
    }

    // Sort cities alphabetically
    final sortedCities = byCity.keys.toList()..sort();

    for (final city in sortedCities) {
      buffer.writeln('=== $city ===');
      final cityPlaces = byCity[city]!;

      // Group places by category within each city
      final byCategory = <String, List<Place>>{};
      for (final place in cityPlaces) {
        byCategory.putIfAbsent(place.category, () => []).add(place);
      }

      // Sort categories alphabetically
      final sortedCategories = byCategory.keys.toList()..sort();

      for (final category in sortedCategories) {
        buffer.writeln('\n-- $category --');
        final categoryPlaces = byCategory[category]!;

        // Sort places by rating (highest first) within category
        categoryPlaces.sort((a, b) => b.rating.compareTo(a.rating));

        for (final place in categoryPlaces) {
          buffer.writeln('• ${place.title}');
          buffer.writeln('  Rating: ${place.rating}/5 (${place.reviewCount} reviews)');
          buffer.writeln('  Description: ${place.description}');
          if (place.localTip.isNotEmpty) {
            buffer.writeln('  Local Tip: ${place.localTip}');
          }
          if (place.contributorIsSuperUser) {
            buffer.writeln('  ⭐ Recommended by a Super User');
          }
          buffer.writeln();
        }
      }
    }

    // Add summary statistics for better queries
    buffer.writeln('\n=== SUMMARY STATISTICS ===');
    buffer.writeln('Total places: ${places.length}');
    buffer.writeln('Cities covered: ${sortedCities.join(", ")}');

    final categories = places.map((p) => p.category).toSet().toList()..sort();
    buffer.writeln('Categories: ${categories.join(", ")}');

    // Find highest rated places overall
    if (places.isNotEmpty) {
      final highestRated = places.where((p) => p.reviewCount > 0)
          .toList()..sort((a, b) => b.rating.compareTo(a.rating));
      if (highestRated.isNotEmpty) {
        buffer.writeln('Highest rated place: ${highestRated.first.title} (${highestRated.first.rating}/5 in ${highestRated.first.city})');
      }
    }

    return buffer.toString();
  }

  // Send message to Gemini API
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check if API key is configured
    if (_apiKey == 'your_api_key_here' || _apiKey.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ));
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "🤖 API Key Not Configured\n\nTo use LocalBot, you need to:\n\n1. Get a Gemini API key from https://makersuite.google.com/app/apikey\n2. Replace 'your_api_key_here' in lib/config/api_config.dart with your actual key\n3. Restart the app\n\nThis keeps your API key secure and not committed to version control.",
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
      _messageController.clear();
      return;
    }

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      // Get all places from provider
      final places =
          Provider.of<AppProvider>(context, listen: false).places;
      final placesContext = _buildPlacesContext(places);

      // Build the prompt — this tells Gemini who it is
      // and gives it all the app data
      final systemPrompt = '''
You are LocalBot, an AI travel guide for the LikeALocal app.
You help tourists experience Egyptian cities like a local.

Your personality:
- Friendly, enthusiastic, and knowledgeable
- Give specific, actionable recommendations
- Always mention local tips when available
- If asked for a multi-day plan, structure it clearly by day
- Keep responses concise but helpful
- Use emojis occasionally to be engaging
- Only recommend places that exist in the app data below
- If no places match what the user wants, say so honestly
- When asked for "highest rated" or "best" places, look at the ratings and review counts
- For recommendations, consider both rating and whether it's recommended by a Super User
- Be specific about cities and categories when answering

IMPORTANT: Only use the places listed below. Do not invent places.

$placesContext

The user says: $text
''';

      // Call Gemini API using the documented generateContent endpoint
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': systemPrompt,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
            'topP': 0.8,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          final content = candidate['content'];
          if (content != null && content['parts'] != null &&
              content['parts'] is List &&
              content['parts'].isNotEmpty &&
              content['parts'][0]['text'] != null) {
            reply = content['parts'][0]['text'] as String;
          } else if (candidate['output'] != null) {
            reply = candidate['output'] as String;
          } else {
            reply = 'Sorry, I could not understand the response from the AI service.';
          }
        } else {
          reply = 'Sorry, the AI service returned an unexpected response.';
        }

        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: reply.trim(),
            isUser: false,
            time: DateTime.now(),
          ));
        });
      } else {
        final bodyText = response.body;
        debugPrint('Gemini error (${response.statusCode}): $bodyText');
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: "Sorry, I couldn't process that right now. (${response.statusCode})",
            isUser: false,
            time: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      debugPrint('Chatbot error: $e');
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text:
              "I'm having trouble connecting right now. Please check your internet and try again.",
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          // Bot avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LocalBot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _isTyping ? 'Typing...' : 'AI Local Guide',
                style: TextStyle(
                  fontSize: 11,
                  color: _isTyping
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ]),
        // Clear chat button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined,
                color: Color(0xFF6B7280), size: 20),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text:
                      "Chat cleared! What would you like to explore? 🗺️",
                  isUser: false,
                  time: DateTime.now(),
                ));
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Suggestion chips ──────────────────────────
          _buildSuggestionChips(),

          // ── Messages list ─────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                // Show typing indicator as last item
                if (_isTyping && i == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[i]);
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // Quick suggestion chips at the top
  Widget _buildSuggestionChips() {
    final suggestions = [
      '3 days in Cairo 🏛️',
      'Best cafes ☕',
      'Hidden gems 💎',
      'Budget food 🍕',
      'Top rated ⭐',
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestions[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                ),
              ),
              backgroundColor: const Color(0xFFEFF6FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                _messageController.text = suggestions[i];
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  // Individual message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar on left
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF2563EB),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Timestamp on right for user messages
          if (isUser) ...[
            const SizedBox(width: 8),
            Text(
              '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ],
      ),
    );
  }

  // Animated typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFF2563EB), size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Animated dot for typing indicator
  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF9CA3AF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Input bar at the bottom
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(children: [
        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask me about any city...',
                hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Send button
        GestureDetector(
          onTap: _isTyping ? null : _sendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isTyping
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.send_rounded,
              color: _isTyping ? const Color(0xFF9CA3AF) : Colors.white,
              size: 18,
            ),
          ),
        ),
      ]),
    );
  }
}