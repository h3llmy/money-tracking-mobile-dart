import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationStreamController = StreamController<Map>.broadcast();
  Stream<Map> get notificationStream => _notificationStreamController.stream;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    bool hasPermission = await NotificationsListener.hasPermission ?? false;
    if (!hasPermission) {
      dev.log("Notification permission not granted");
      return;
    }

    // Start the native notification listener service
    try {
      final isRunning = await NotificationsListener.isRunning ?? false;
      if (!isRunning) {
        dev.log("Starting native notification listener service...");
        await NotificationsListener.startService();
      }
    } catch (e) {
      dev.log("Error starting native notification listener service: $e");
    }

    ReceivePort port = ReceivePort();
    IsolateNameServer.removePortNameMapping("_listener_");
    IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");

    port.listen((message) {
      if (message is Map) {
        dev.log(
          "UI: Notification received from background: ${message['packageName']}",
        );
        _notificationStreamController.add(message);
      }
    });

    _isInitialized = true;
    dev.log(
      "Notification Service Fully Initialized (Listening for UI updates)",
    );
  }

  Future<void> requestPermission() async {
    await NotificationsListener.openPermissionSettings();
  }
}
