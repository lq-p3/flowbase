import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart' show Task, Project;
import 'format.dart';

/// Phone notifications scheduled on the device itself (free, no server, works offline).
///
/// iOS keeps at most 64 pending notifications per app, so we always cancel
/// everything and schedule only the nearest ones again after each change.
class Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
    android: AndroidNotificationDetails('reminders', 'Reminders', importance: Importance.high, priority: Priority.high),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Unknown zone name: keep UTC.
    }
    // Permission is asked later (after sign-in), not at launch.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(iOS: darwin, android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  /// Shows the iOS "Allow notifications?" prompt the first time; later calls return the saved answer.
  Future<bool> askPermission() async {
    if (!_ready) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ok = await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        await android?.requestNotificationsPermission() ??
        false;
    return ok;
  }

  /// Rebuilds the whole schedule from the current data.
  Future<void> reschedule({
    required List<Task> tasks,
    required List<Project> projects,
    required bool taskReminders,
    required bool dueReminders,
    required bool isAr,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    final f = Fmt(isAr);
    final jobs = <(tz.TZDateTime, String, String)>[];

    // 1. Each task with a time and the reminder switch on: 30 minutes before it starts.
    if (taskReminders) {
      for (final t in tasks) {
        if (t.isDone || !t.reminder || t.time == null) continue;
        final hm = t.time!.split(':').map(int.parse).toList();
        final at = tz.TZDateTime(tz.local, t.date.year, t.date.month, t.date.day, hm[0], hm[1]).subtract(const Duration(minutes: 30));
        if (at.isAfter(now)) {
          jobs.add((at, t.title.of(isAr), isAr ? 'تبدأ الساعة ${f.time(t.time)} (بعد ٣٠ دقيقة)' : 'Starts at ${f.time(t.time)} (in 30 minutes)'));
        }
      }
    }

    if (dueReminders) {
      // 2. Morning summary at 8:00 for the next 7 days that have open tasks.
      for (var i = 0; i < 7; i++) {
        final day = DateTime(now.year, now.month, now.day + i);
        final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, 8);
        if (!at.isAfter(now)) continue;
        final open = tasks.where((t) => !t.isDone && t.date.year == day.year && t.date.month == day.month && t.date.day == day.day).length;
        if (open == 0) continue;
        jobs.add((
          at,
          isAr ? 'صباح الخير ☀️' : 'Good morning ☀️',
          isAr ? 'عندك ${f.nTasks(open)} اليوم' : 'You have ${f.nTasks(open)} today',
        ));
      }
      // 3. Project due dates: 9:00 on the due day.
      for (final p in projects) {
        final at = tz.TZDateTime(tz.local, p.due.year, p.due.month, p.due.day, 9);
        if (at.isAfter(now)) {
          jobs.add((at, p.name.of(isAr), isAr ? 'موعد تسليم المشروع اليوم' : 'This project is due today'));
        }
      }
    }

    jobs.sort((a, b) => a.$1.compareTo(b.$1));
    var id = 0;
    for (final (at, title, body) in jobs.take(60)) {
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: at,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
