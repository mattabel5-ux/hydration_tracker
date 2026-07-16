import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/daily_hydration.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class HydrationNotifier extends Notifier<DailyHydration?> {
  @override
  DailyHydration? build() {
    // Schedule the 8:00 AM fallback alarm in case they haven't set up the app today
    NotificationService.scheduleSetupReminder();
    return null; // Initial state is null while waiting for DB to load
  }

  String get _todayDateId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadToday() async {
    final data = await DatabaseHelper.instance.getHydration(_todayDateId);
    state = data;
    if (state != null) {
      _updateSmartNotification(); // Schedules the interval batch on app load
    }
  }

  Future<void> setupDay({
    required double goalOz,
    required double bottleSize,
    required DateTime firstDrink,
    required DateTime bedtime,
  }) async {
    final newDay = DailyHydration(
      dateId: _todayDateId,
      goalOz: goalOz,
      bottleSize: bottleSize,
      firstDrinkEpoch: firstDrink.millisecondsSinceEpoch,
      bedtimeEpoch: bedtime.millisecondsSinceEpoch,
      totalDrankOz: 0.0,
      refillCount: 0,
      electrolytePills: 0,
      // Notification settings will safely fall back to 60 min and 'standard' here
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(newDay);
    state = newDay;
    _updateSmartNotification();
  }

  Future<void> addRefill() async {
    if (state == null) return;
    final updatedDay = state!.copyWith(
      totalDrankOz: state!.totalDrankOz + state!.bottleSize,
      refillCount: state!.refillCount + 1,
    );
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification();
  }

  Future<void> addCustomWater(double oz) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(
      totalDrankOz: state!.totalDrankOz + oz,
    );
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification();
  }

  Future<void> addElectrolytePill() async {
    if (state == null) return;
    final updatedDay = state!.copyWith(
        electrolytePills: state!.electrolytePills + 1
    );
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
  }

  // --- EDIT METHODS ---

  Future<void> updateGoal(double newGoal) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(goalOz: newGoal);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification();
  }

  Future<void> updateBottleSize(double newSize) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(bottleSize: newSize);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
  }

  Future<void> updateFirstDrink(int newEpochMs) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(firstDrinkEpoch: newEpochMs);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification();
  }

  Future<void> updateBedtime(int newEpochMs) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(bedtimeEpoch: newEpochMs);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification();
  }

  // --- NEW: Edit Notification Settings ---
  Future<void> updateNotificationSettings(int intervalMinutes, String type) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(
      notificationIntervalMinutes: intervalMinutes,
      notificationType: type,
    );
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification(); // Wipes the old schedule and recreates the new batch!
  }

  double get dynamicHourlyGoal {
    if (state == null) return 0.0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final bedtimeMs = state!.bedtimeEpoch;

    if (nowMs >= bedtimeMs) return 0.0;

    final remainingOz = state!.goalOz - state!.totalDrankOz;
    if (remainingOz <= 0) return 0.0;

    final remainingHours = (bedtimeMs - nowMs) / (1000 * 60 * 60);
    return remainingOz / remainingHours;
  }

  void _updateSmartNotification() {
    final currentData = state;
    if (currentData == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (nowMs >= currentData.bedtimeEpoch) {
      NotificationService.cancelAllNotifications();
      return;
    }

    final drank = currentData.totalDrankOz.toStringAsFixed(0);
    final hourlyTarget = dynamicHourlyGoal.toStringAsFixed(1);

    String message = "You have drank $drank oz so far. To hit your goal, aim for $hourlyTarget oz/hr the rest of the day.";

    NotificationService.scheduleAutomatedNudges(
      message: message,
      intervalMinutes: currentData.notificationIntervalMinutes,
      bedtimeEpoch: currentData.bedtimeEpoch,
      type: currentData.notificationType,
    );
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, DailyHydration?>(() {
  return HydrationNotifier();
});