import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/nets_service.dart';
import 'package:flutter_application_1/widgets/nets_fail.dart';
import 'package:flutter_application_1/widgets/nets_success.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';

class NETSQR extends StatefulWidget {
  final Function register;
  NETSQR(this.register, {super.key});

  @override
  State<NETSQR> createState() => _NETSQRState();
}

class _NETSQRState extends State<NETSQR> {
  NETSService netsService = GetIt.instance<NETSService>();

  Uint8List? qrCode;
  String? txnRetrievalRef;
  String? responseCode;
  String? message;
  bool _completed = false;

  int? timeLeft = 300;
  String formattedTime = '';

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    getQrCode(); // Initialize QR code and start webhook

    // Start countdown timer for QR code validity
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft! > 0) {
        setState(() {
          timeLeft = timeLeft! - 1;
          formattedTime =
              '${(timeLeft! ~/ 60).toString().padLeft(2, '0')}:${(timeLeft! % 60).toString().padLeft(2, '0')}';
        });
      } else {
        timer.cancel(); // Stop the timer when it reaches zero
        netsService.cancelWebhook(); // Cancel webhook if time runs out
        queryAPI(txnRetrievalRef!); // Check final transaction status
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel(); // Cancel the timer when widget is disposed
    netsService.cancelWebhook(); // Cancel webhook when widget is disposed
  }

  // Requests the QR code from the NETS service and decodes it for display.
  // Initiates the webhook listener for the transaction.
  void getQrCode() async {
    Response requestResponse = await netsService.requestAPI();
    var data = requestResponse.body;
    var decodedData = jsonDecode(data);
    setState(() {
      qrCode = base64Decode(decodedData['result']['data']['qr_code']);
    });
    txnRetrievalRef = decodedData['result']['data']['txn_retrieval_ref'];

    getWebHookAPI(txnRetrievalRef);
  }

  // Listens for updates on the QR transaction using webhook,
  // Extracts message and response code from the stream.
  void getWebHookAPI(txnRetrievalRef) async {
    print('txnRetrievalRef: $txnRetrievalRef');

    Response requestResponse = await netsService.webhookAPI(txnRetrievalRef);
    final responseBody = requestResponse.body;

    if (responseBody.contains('data:')) {
      String jsonData = responseBody.split('data:')[1];
      var decodedData = jsonDecode(jsonData);

      setState(() {
        message = decodedData['message'];
        responseCode = decodedData['response_code'];
      });

      // Auto-complete on success once
      if (!_completed && message == 'QR code scanned' && responseCode == '00') {
        _completed = true;
        // Stop listening and countdown
        netsService.cancelWebhook();
        if (_timer.isActive) _timer.cancel();
        // Notify parent
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.register(context);
        });
      }
    }
  }

  // Makes a final query to the NETS API to get the transaction status in case the QR code expires or the webhook doesn't return in time.
  void queryAPI(String txnRetrievalRef) async {
    Response requestResponse = await netsService.queryAPI(txnRetrievalRef);
    var data = requestResponse.body;
    var decodedData = jsonDecode(data);
    setState(() {
      responseCode = decodedData['result']['data']['response_code'];
    });
  }

  // Builds the QR code widget along with timer and info image.
  Widget displayQRCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (qrCode != null) Image.memory(qrCode!),
        if (responseCode != '00')
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Image.asset(
          'assets/images/netsQrInfo.png',
          width: MediaQuery.of(context).size.width * 0.8,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Builds the UI based on the QR code and transaction state.
  // Displays QR code, success/fail status, and registration button.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        qrCode != null &&
                timeLeft! > 0 &&
                responseCode == null &&
                message == null
            ? displayQRCode()
            : message == 'QR code scanned' && responseCode == '00'
                ? NETSSuccess()
                : responseCode != null
                    ? NETSFail()
                    : message == "Timeout"
                        ? displayQRCode()
                        : Center(),
      ],
    );
  }
}
