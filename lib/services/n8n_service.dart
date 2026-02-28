/// CabEasy - N8nService
/// Purpose: Handle n8n webhook integration for lead classification
/// Author: CabEasy Dev

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/app_config.dart';

class N8nService {
  // When agent posts a request, call this AFTER saving to Firestore
  // This triggers the lead classification workflow
  static Future<void> triggerLeadClassification({
    required String requestId,
    required String pickupLocation,
    required String dropLocation,
    required DateTime travelDate,
    required int passengerCount,
    required String vehicleType,
    required String agentId,
  }) async {
    try {
      final url = Uri.parse(AppConfig.n8nWebhookUrl);

      final payload = {
        'requestId': requestId,
        'pickupLocation': pickupLocation,
        'dropLocation': dropLocation,
        'travelDate': travelDate.toIso8601String(),
        'passengerCount': passengerCount,
        'vehicleType': vehicleType,
        'agentId': agentId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 400) {
        debugPrint('n8n webhook returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Log silently - do not throw error as this is non-critical
      debugPrint('n8n webhook failed (non-critical): $e');
    }
  }

  // Secondary webhook call requested for agent form submission payload.
  static Future<void> sendAgentFormPayload({
    required String destination,
    required String cabType,
    required String pax,
    required String noOfNights,
    required String pickUp,
    required String detailedItinerary,
    required DateTime startDate,
    required String leadPaxName,
    required String phone,
    required bool flightsBooked,
    required bool hotelsBooked,
    required String minBudget,
    required String maxBudget,
    required bool needsPackage,
    required String reqId,
  }) async {
    try {
      final Uri url = Uri.parse(AppConfig.agentFormWebhookTestUrl);
      final Map<String, dynamic> payload = <String, dynamic>{
        'destination': destination,
        'cabType': cabType,
        'pax': pax,
        'noOfNights': noOfNights,
        'pickUp': pickUp,
        'detailedItinerary': detailedItinerary,
        'startDate': startDate.toIso8601String().split('T').first,
        'leadPaxName': leadPaxName,
        'phone': phone,
        'flightsBooked': flightsBooked,
        'hotelsBooked': hotelsBooked,
        'minBudget': minBudget,
        'maxBudget': maxBudget,
        'needsPackage': needsPackage,
        'req_id': reqId,
      };

      final http.Response response = await http.post(
        url,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 400) {
        debugPrint(
          'agent form webhook returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('agent form webhook failed (non-critical): $e');
    }
  }
}
