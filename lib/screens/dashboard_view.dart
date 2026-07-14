import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/hydration_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state so the UI rebuilds every time she hits refill
    final dailyState = ref.watch(hydrationProvider);
    final notifier = ref.read(hydrationProvider.notifier);

    // Safety check: if state is somehow null, don't try to draw the screen
    if (dailyState == null) return const SizedBox.shrink();

    // --- Math for the UI ---
    // Cap the percent at 1.0 (100%) so the circle indicator doesn't crash if she overachieves
    final percent = (dailyState.totalDrankOz / dailyState.goalOz).clamp(0.0, 1.0);
    final hourlyGoal = notifier.dynamicHourlyGoal;

    // Ahead / Behind Schedule Logic
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = nowMs - dailyState.firstDrinkEpoch;
    final totalDurationMs = dailyState.bedtimeEpoch - dailyState.firstDrinkEpoch;

    String statusText = "On Track";
    Color statusColor = Colors.green;

    // Only calculate pace if the day has started and isn't over yet
    if (totalDurationMs > 0 && nowMs > dailyState.firstDrinkEpoch && nowMs < dailyState.bedtimeEpoch) {
      final expectedPace = dailyState.goalOz * (elapsedMs / totalDurationMs);
      final difference = dailyState.totalDrankOz - expectedPace;

      if (difference > 0) {
        statusText = "Ahead of schedule (+${difference.toStringAsFixed(1)} oz)";
        statusColor = Colors.blue;
      } else if (difference < 0) {
        statusText = "Behind schedule (${difference.toStringAsFixed(1)} oz)";
        statusColor = Colors.orange;
      }
    } else if (nowMs >= dailyState.bedtimeEpoch) {
      statusText = dailyState.totalDrankOz >= dailyState.goalOz ? "Goal Met!" : "Day Over - Goal Missed";
      statusColor = dailyState.totalDrankOz >= dailyState.goalOz ? Colors.green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Goal Progress Ring
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 20.0,
            animation: true,
            animateFromLastPercent: true,
            percent: percent,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${dailyState.totalDrankOz.toStringAsFixed(0)} oz",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36.0),
                ),
                Text(
                  "/ ${dailyState.goalOz.toStringAsFixed(0)} oz",
                  style: const TextStyle(fontSize: 18.0, color: Colors.grey),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.blue,
            backgroundColor: Colors.blue.withValues(alpha:0.15),
          ),

          // 2. Status and Target Readout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha:0.5), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  "Current Target: ${hourlyGoal.toStringAsFixed(1)} oz / hr",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // 3. Actions
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => notifier.addRefill(),
                  icon: const Icon(Icons.water_drop),
                  label: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'Refilled Bottle (+${dailyState.bottleSize.toStringAsFixed(0)} oz)',
                        style: const TextStyle(fontSize: 18)
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Total Refills Today: ${dailyState.refillCount}',
                  style: const TextStyle(color: Colors.grey)
              ),
            ],
          ),

          // 4. Supplements Logged
          const Divider(),
          const Text(
            'Supplements Logged',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Single Combined Tracker
          Column(
            children: [
              Text(
                '${dailyState.electrolytePills}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Salt/Potassium Capsules', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(hydrationProvider.notifier).addElectrolytePill();
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Capsule'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}