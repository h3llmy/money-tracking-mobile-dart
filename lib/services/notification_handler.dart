import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Background callback invoked by the flutter_notification_listener plugin.
///
/// NOTE: The actual HTTP sync is handled reliably by the NativeNotificationService (Kotlin)
/// even when the app is killed. This Dart callback is primarily for notifying the
/// UI isolate when the app is alive.
@pragma('vm:entry-point')
void onNotificationBackgroundCallback(NotificationEvent event) async {
  print("--- Dart Background Callback triggered for ${event.packageName} ---");
  await NotificationBackgroundHandler.handle(event);
}

class NotificationBackgroundHandler {
  @pragma('vm:entry-point')
  static Future<void> handle(NotificationEvent event) async {
    print("--- Notification Event Received ---");
    print("PackageName: ${event.packageName}");
    print("Title: ${event.title}");
    print("Text: ${event.text}");
    print("Key: ${event.key}");
    print("ID: ${event.id}");

    String packageName = event.packageName ?? "";
    bool isSimulated = false;

    // If notification is from shell (ADB simulation), extract real package name from notification tag/key
    if (packageName == "com.android.shell" && event.key != null) {
      final parts = event.key!.split('|');
      if (parts.length >= 4 && parts[3] != "null" && parts[3].isNotEmpty) {
        packageName = parts[3];
        isSimulated = true;
        print(
          "Simulated ADB notification: overriding package com.android.shell with tag '$packageName'",
        );
      }
    }

    // Check if the app is allowed
    try {
      final prefs = await SharedPreferences.getInstance();
      final allowAll = prefs.getBool('allow_all_notifications') ?? false;
      final allowedApps = prefs.getStringList('allowed_apps') ?? [];

      // We always allow ADB simulations for easy developer testing.
      // Otherwise, check if allowAll is true or the app is in the allowed list.
      if (!isSimulated &&
          !allowAll &&
          allowedApps.isNotEmpty &&
          !allowedApps.contains(packageName)) {
        print("Ignored notification from non-allowed app: $packageName");
        return;
      }
    } catch (e) {
      print("Failed to check allowed apps: $e");
    }

    // Perform the sync to the backend using ApiService
    try {
      print("--- STARTING BACKGROUND API SYNC ---");
      print("Event Data: Title='${event.title}', Text='${event.text}'");

      // Use text or title as the body, ensuring it's not null
      final body = event.text ?? event.title ?? "No Content";
      final title = (body == event.title) ? null : event.title;

      final apiService = await ApiService.create();
      await apiService.syncNotifications([
        {"app_package": packageName, "raw_title": title, "raw_body": body},
      ]);

      print("Background Sync Successful: $packageName");
    } catch (e) {
      print("Background Sync Failed: $e");
    }

    // Forward the event to the UI isolate so it can refresh the screen
    final SendPort? send = IsolateNameServer.lookupPortByName("_listener_");
    if (send != null) {
      send.send({
        "packageName": packageName,
        "title": event.title,
        "text": event.text,
      });
    } else {
      print("UI isolate not found, event only processed by Native layer.");
    }
  }
}
