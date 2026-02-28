/// CabEasy - ChatProvider
/// Purpose: Provider for chat state management with local storage
/// Author: CabEasy Dev

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentStreamingWord;
  int _currentMessageIndex = -1;

  // For word-by-word animation
  String _displayedText = '';
  bool _isStreaming = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayedText => _displayedText;
  bool get isStreaming => _isStreaming;
  int get currentMessageIndex => _currentMessageIndex;

  static const String _storageKey = 'cabeasy_chat_messages';

  /// Initialize chat with saved messages or empty
  ChatProvider() {
    _loadMessages();
  }

  /// Load messages from local storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedMessages = prefs.getString(_storageKey);

      if (storedMessages != null && storedMessages.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storedMessages);
        _messages = decoded.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        _messages = [];
      }
    } catch (e) {
      _messages = [];
    }
    notifyListeners();
  }

  /// Save messages to local storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  /// Send a message and get AI response with word-by-word animation
  Future<void> sendMessage(String content, String userId) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    await _saveMessages();

    _isLoading = true;
    _isStreaming = true;
    _error = null;
    _displayedText = '';
    _currentMessageIndex = _messages.length;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(
        message: content.trim(),
        userId: userId,
      );

      // Create bot message placeholder
      final botMessage = ChatMessage(
        role: ChatRole.bot,
        content: response.message,
        timestamp: DateTime.now(),
      );
      _messages.add(botMessage);
      _currentMessageIndex = _messages.length - 1;

      // Word-by-word animation
      await _animateText(response.message);
    } on ChatException catch (e) {
      _error = e.message;
      final errorMessage = ChatMessage(
        role: ChatRole.bot,
        content: 'Oops! Something went wrong. Please try again or contact CabEasy customer care for assistance.',
        timestamp: DateTime.now(),
        isError: true,
      );
      _messages.add(errorMessage);
      await _saveMessages();
    } catch (e) {
      _error = 'An unexpected error occurred';
      final errorMessage = ChatMessage(
        role: ChatRole.bot,
        content: 'We\'re having trouble connecting right now. Please check your internet and try again, or reach out to CabEasy customer care.',
        timestamp: DateTime.now(),
        isError: true,
      );
      _messages.add(errorMessage);
      await _saveMessages();
    } finally {
      _isLoading = false;
      _isStreaming = false;
      _displayedText = '';
      notifyListeners();
    }
  }

  /// Animate text word by word
  Future<void> _animateText(String fullText) async {
    final words = fullText.split(' ');
    _displayedText = '';

    for (int i = 0; i < words.length; i++) {
      if (!_isStreaming) break;

      _displayedText += words[i];
      if (i < words.length - 1) {
        _displayedText += ' ';
      }

      // Update the last message with animated text
      if (_currentMessageIndex >= 0 && _currentMessageIndex < _messages.length) {
        _messages[_currentMessageIndex] = ChatMessage(
          role: ChatRole.bot,
          content: _displayedText,
          timestamp: _messages[_currentMessageIndex].timestamp,
        );
      }

      notifyListeners();

      // Delay between words for animation effect
      await Future.delayed(const Duration(milliseconds: 30));
    }

    // Final save after animation completes
    await _saveMessages();
  }

  /// Stop streaming (for cancel)
  void stopStreaming() {
    _isStreaming = false;
    _saveMessages();
    notifyListeners();
  }

  /// Clear all messages
  Future<void> clearChat() async {
    _messages = [];
    _error = null;
    _displayedText = '';
    _isStreaming = false;
    await _saveMessages();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
