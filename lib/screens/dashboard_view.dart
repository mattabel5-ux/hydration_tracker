import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/hydration_provider.dart';
import '../services/notification_service.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  Future<void> _showCustomAmountDialog(BuildContext context, HydrationNotifier notifier) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Highlights text on tap
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          decoration: const InputDecoration(
            labelText: 'Amount (oz)',
            suffixText: 'oz',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                notifier.addCustomWater(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(hydrationProvider);
    final notifier = ref.read(hydrationProvider.notifier);

    if (dailyState == null) return const SizedBox.shrink();

    final percent = (dailyState.totalDrankOz / dailyState.goalOz).clamp(0.0, 1.0);
    final hourlyGoal = notifier.dynamicHourlyGoal;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = nowMs - dailyState.firstDrinkEpoch;
    final totalDurationMs = dailyState.bedtimeEpoch - dailyState.firstDrinkEpoch;

    String statusText = "On Track";
    Color statusColor = Colors.green;

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

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

            const SizedBox(height: 32),

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

            const SizedBox(height: 32),

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
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Total Refills Today: ${dailyState.refillCount}',
                        style: const TextStyle(color: Colors.grey)
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                        onPressed: () => _showCustomAmountDialog(context, notifier),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Custom Amount')
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Supplements Logged',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Text(
                  '${dailyState.electrolytePills}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('Salt/Potassium Capsules', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    notifier.addElectrolytePill();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Log Capsule'),
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}