import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _eventsStream;
  bool _primed = false;

  Future<void> init() async {
    if (kIsWeb) return; // local notifications not supported on Flutter web
    if (_initialized) return;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await _fln.initialize(initSettings);
    _initialized = true;
  }

  Future<void> startListeningForNewEvents() async {
    if (kIsWeb) return;
    await init();

    // Only listen on mobile platforms
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    _eventsStream ??= FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();

    _eventsStream!.listen((snapshot) async {
      // On first snapshot, seed last seen without notifying
      if (!_primed) {
        _primed = true;
        if (snapshot.docs.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastNotifiedEventId', snapshot.docs.first.id);
        }
        return;
      }
      if (snapshot.docChanges.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('lastNotifiedEventId');
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final title = (data?['title']?.toString() ?? 'New Event');
          final desc = (data?['description']?.toString() ?? '');
          if (change.doc.id != lastId) {
            await _showNotification(title: title, body: desc);
            await prefs.setString('lastNotifiedEventId', change.doc.id);
          }
        }
      }
    });
  }

  Future<void> _showNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'events_channel',
      'Events',
      channelDescription: 'Notifications for new events',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.show(0, title, body, details);
  }
}
