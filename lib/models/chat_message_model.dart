/// CabEasy - ChatMessageModel
/// Purpose: Data model for chat messages
/// Author: CabEasy Dev

enum ChatRole { user, bot }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == ChatRole.user;
  bool get isBot => role == ChatRole.bot;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'role': role.index,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: ChatRole.values[json['role'] as int],
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isError: json['isError'] as bool? ?? false,
    );
  }
}
