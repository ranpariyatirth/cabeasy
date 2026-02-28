/// CabEasy - ChatService
/// Purpose: Handle AI chatbot API communication
/// Author: CabEasy Dev

import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _baseUrl = 'https://agent.cabeasy.in/webhook/input';

  /// Send a message to the AI chatbot and get response
  Future<ChatResponse> sendMessage({
    required String message,
    required String userId,
  }) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final encodedUserId = Uri.encodeComponent(userId);
      final url = '$_baseUrl?message=$encodedMessage&userId=$encodedUserId';

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ChatException('Request timed out'),
          );

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        throw ChatException('Server error: ${response.statusCode}');
      }
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException('Connection error: ${e.toString()}');
    }
  }

  ChatResponse _parseResponse(String body) {
    try {
      // Check for empty body
      if (body.trim().isEmpty) {
        throw ChatException('Empty response from server');
      }

      final data = jsonDecode(body);
      if (data is Map) {
        final reply = data['finalReply']?.toString();

        // Check if reply is null, empty, or contains error indicators
        if (reply == null || reply.trim().isEmpty) {
          throw ChatException('No response received');
        }

        // Check for common error patterns in the response
        final lowerReply = reply.toLowerCase();
        if (lowerReply.contains('internal server error') ||
            lowerReply.contains('502 bad gateway') ||
            lowerReply.contains('503 service') ||
            lowerReply == 'error' ||
            lowerReply == 'null') {
          throw ChatException('Server returned an error');
        }

        return ChatResponse(success: true, message: reply);
      }

      // Non-JSON response - check if it looks like an error
      final lowerBody = body.toLowerCase();
      if (lowerBody.contains('error') || lowerBody.contains('exception')) {
        throw ChatException('Server returned an error');
      }

      return ChatResponse(success: true, message: body);
    } on ChatException {
      rethrow;
    } catch (_) {
      // If not JSON and not parseable, return body as message
      if (body.trim().isEmpty) {
        throw ChatException('Empty response from server');
      }
      return ChatResponse(success: true, message: body);
    }
  }
}

/// Chat response model
class ChatResponse {
  final bool success;
  final String message;

  ChatResponse({required this.success, required this.message});
}

/// Custom exception for chat errors
class ChatException implements Exception {
  final String message;
  ChatException(this.message);

  @override
  String toString() => message;
}
