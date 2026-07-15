import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/daily_hydration.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

// The Notifier controls the state of our DailyHydration object
class HydrationNotifier extends Notifier<DailyHydration?> {
  @override
  DailyHydration? build() {
    // Initial state is null while we wait for the database to load
    return null;
  }

  // Helper to always get the current day in YYYY-MM-DD format
  String get _todayDateId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 1. Loads today's data from SQLite when the app opens
  Future<void> loadToday() async {
    final data = await DatabaseHelper.instance.getHydration(_todayDateId);
    state = data;
    _updateSmartNotification(); // Schedules the notification on app load
  }

  // 2. Sets up a new day if she hasn't entered her info yet
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
      electrolytePills: 0, // Set to 0 at the start of the day
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(newDay);
    state = newDay;
    _updateSmartNotification(); // Schedules the notification when starting the day
  }

  // 3. Adds a refill, recalculates, and saves to database
  Future<void> addRefill() async {
    if (state == null) return;

    final updatedDay = state!.copyWith(
      totalDrankOz: state!.totalDrankOz + state!.bottleSize,
      refillCount: state!.refillCount + 1,
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay; // Triggers the UI to rebuild
    _updateSmartNotification(); // Recalculates pace and reschedules notification
  }

  // Adds a custom amount of water (e.g., from a glass instead of the main bottle)
  Future<void> addCustomWater(double oz) async {
    if (state == null) return;

    final updatedDay = state!.copyWith(
      totalDrankOz: state!.totalDrankOz + oz,
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay; // Triggers UI rebuild
    _updateSmartNotification(); // Recalculates pace
  }

  // Adds a combined Salt/Potassium tablet
  Future<void> addElectrolytePill() async {
    if (state == null) return;

    final updatedDay = state!.copyWith(
        electrolytePills: state!.electrolytePills + 1
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay; // Triggers the UI to rebuild
  }

  // --- NEW EDIT METHODS ---

  Future<void> updateGoal(double newGoal) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(goalOz: newGoal);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    _updateSmartNotification(); // Recalculate hourly pace
  }

  Future<void> updateBottleSize(double newSize) async {
    if (state == null) return;
    final updatedDay = state!.copyWith(bottleSize: newSize);
    await DatabaseHelper.instance.insertOrUpdateHydration(updatedDay);
    state = updatedDay;
    // Changing bottle size doesn't affect the hourly math, so no notification update needed
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
    _updateSmartNotification(); // Math changes drastically if bedtime changes
  }

  // 4. The Math: Calculates exactly how much she needs to drink per hour right now
  double get dynamicHourlyGoal {
    if (state == null) return 0.0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final bedtimeMs = state!.bedtimeEpoch;

    // If it's past bedtime, or she already met her goal, she needs 0 oz/hr
    if (nowMs >= bedtimeMs) return 0.0;

    final remainingOz = state!.goalOz - state!.totalDrankOz;
    if (remainingOz <= 0) return 0.0;

    final remainingHours = (bedtimeMs - nowMs) / (1000 * 60 * 60);
    return remainingOz / remainingHours;
  }

  // 5. Smart Notification Logic
  void _updateSmartNotification() {
    final currentData = state;
    if (currentData == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // If the tracking window for the day has already passed, don't send nudges
    if (nowMs >= currentData.bedtimeEpoch) {
      NotificationService.cancelAllNotifications();
      return;
    }

    // Grab the exact numbers she asked for
    final drank = currentData.totalDrankOz.toStringAsFixed(0);
    final hourlyTarget = dynamicHourlyGoal.toStringAsFixed(1);

    // Format the exact message she wants to see
    String message = "You have drank $drank oz so far. To hit your goal, aim for $hourlyTarget oz/hr the rest of the day.";

    // Pass it to your notification service
    NotificationService.scheduleNudge(message);
  }
}

// This is the global provider we will watch from our UI widgets
final hydrationProvider = NotifierProvider<HydrationNotifier, DailyHydration?>(() {
  return HydrationNotifier();
});