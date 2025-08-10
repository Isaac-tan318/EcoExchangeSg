import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class NETSService {
  final String API_KEY = 'GiyNoMFXeNaWHpHzYM6Y';
  final String PROJECT_ID = 'e67b2c4c-ce98-495c-b032-e6de892b315b';

  // Stream subscription used to listen to Server-Sent Events (SSE)
  StreamSubscription<String>? SSEsubscription;

  // Cancels the SSE stream if active
  void cancelWebhook() {
    SSEsubscription?.cancel();
    debugPrint('Webhook stream cancelled');
  }

  // Sends a request to generate a NETS QR payment transaction
  Future<Response> requestAPI() async {
    try {
      Uri url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/request',
      );

      final response = await post(
        url,
        body: jsonEncode({
          'txn_id':
              'sandbox_nets|m|8ff8e5b6-d43e-4786-8ac5-7accf8c5bd9b', // Fixed sandbox transaction ID
          'amt_in_dollars': 2, // Amount to be paid (SGD $2)
          'notify_mobile': 0,
        }),
        headers: {
          'Content-Type': 'application/json',
          'api-key': API_KEY,
          'project-id': PROJECT_ID,
        },
      );

      return response;
    } catch (e) {
      // Return a 500 response if an exception occurs
      debugPrint("Exception: $e");
      return Response(
        '{"error": "Error occurred: $e"}',
        500,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Listens for real-time payment status updates from NETS using SSE
  Future<Response> webhookAPI(String txnRetrievalRef) async {
    final maxRetries = 2;
    var attempt = 0;
    bool success = false;

    while (attempt < maxRetries && !success) {
      debugPrint("Webhook Attempt: $attempt");
      try {
        final client = Client();
        final url = Uri.parse(
          'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets/webhook?txn_retrieval_ref=$txnRetrievalRef',
        );

        final request = Request('GET', url)
          ..headers.addAll({
            'Accept': 'text/event-stream',
            'Connection': 'keep-alive',
            'api-key': API_KEY,
            'project-id': PROJECT_ID,
          });

        final streamedResponse = await client.send(request);

        // If the stream starts successfully
        if (streamedResponse.statusCode == 200) {
          final completer = Completer<Response>();
          final buffer = StringBuffer();

          // Listen to the SSE stream
          SSEsubscription = streamedResponse.stream
              .transform(utf8.decoder)
              .listen(
                (chunk) {
                  buffer.write(chunk);
                  // Complete the future if 'data:' is received
                  if (buffer.toString().contains('data:')) {
                    completer.complete(Response(buffer.toString(), 200));
                  }
                },
                onError: (e) {
                  debugPrint("Stream error: $e");
                  completer.completeError(e);
                },
                onDone: () {
                  // Handle completion if stream ends
                  if (!completer.isCompleted) {
                    completer.complete(Response(buffer.toString(), 200));
                  }
                  client.close();
                },
              );

          final response = await completer.future;
          success = true;
          return response;
        }
      } catch (e) {
        debugPrint("Webhook error: $e");
      } finally {
        attempt++;
        await Future.delayed(Duration(seconds: 2));
      }
    }

    // If all retry attempts fail
    return Response(
      '{"error": "Max retry attempts reached"}',
      500,
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Queries the latest payment status using the transaction retrieval reference
  Future<Response> queryAPI(String txnRetrievalRef) async {
    try {
      Uri url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/query',
      );

      final response = await post(
        url,
        body: jsonEncode({
          'txn_retrieval_ref': txnRetrievalRef,
          'frontend_timeout_status': 1, // Indicates frontend timeout scenario
        }),
        headers: {
          'Content-Type': 'application/json',
          'api-key': API_KEY,
          'project-id': PROJECT_ID,
        },
      );

      debugPrint(response.toString());
      return response;
    } catch (e) {
      debugPrint("Exception: $e");
      return Response(
        '{"error": "Error occurred: $e"}',
        500,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
