import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/daily_hydration.dart';
import '../database/database_helper.dart';

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
    );

    await DatabaseHelper.instance.insertOrUpdateHydration(newDay);
    state = newDay;
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
}

// This is the global provider we will watch from our UI widgets
final hydrationProvider = NotifierProvider<HydrationNotifier, DailyHydration?>(() {
  return HydrationNotifier();
});