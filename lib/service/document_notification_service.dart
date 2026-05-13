import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import '../models/vehicle_document.dart';

class DocumentNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzData.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  static Future<void> scheduleAll(List<VehicleDocument> docs) async {
    await _plugin.cancelAll();
    for (final doc in docs) {
      await _scheduleForDocument(doc);
    }
  }

  static Future<void> _scheduleForDocument(VehicleDocument doc) async {
    final typeLabel =
        doc.type == 'license' ? 'Vehicle License' : 'Vehicle Insurance';
    // Notify 30, 7, and 1 day before expiry
    for (final daysBefore in [30, 7, 1]) {
      final notifyAt = doc.expiryDate.subtract(Duration(days: daysBefore));
      if (notifyAt.isAfter(DateTime.now())) {
        final id = (doc.id.hashCode + daysBefore).abs() % 100000;
        await _plugin.zonedSchedule(
          id,
          '⚠️ $typeLabel Expiring Soon',
          '${doc.label}${doc.vehiclePlate.isNotEmpty ? " (${doc.vehiclePlate})" : ""} expires on ${doc.formattedExpiry}',
          tz.TZDateTime.from(notifyAt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'doc_expiry_channel',
              'Document Expiry Alerts',
              channelDescription: 'Alerts for license and insurance expiry',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}
