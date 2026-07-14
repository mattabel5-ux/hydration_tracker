import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/hydration_provider.dart';

class DailyPlanView extends ConsumerWidget {
  const DailyPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(hydrationProvider);

    // Safety check
    if (dailyState == null) return const SizedBox.shrink();

    // Convert saved timestamps back into readable DateTimes
    final firstDrink = DateTime.fromMillisecondsSinceEpoch(dailyState.firstDrinkEpoch);
    final bedtime = DateTime.fromMillisecondsSinceEpoch(dailyState.bedtimeEpoch);

    // Formatter to make the time look like "8:00 AM"
    final timeFormat = DateFormat.jm();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Today\'s Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Data Cards
          _buildInfoCard('Daily Goal', '${dailyState.goalOz.toStringAsFixed(0)} oz', Icons.flag),
          _buildInfoCard('Bottle Size', '${dailyState.bottleSize.toStringAsFixed(0)} oz', Icons.local_drink),
          _buildInfoCard('First Drink', timeFormat.format(firstDrink), Icons.wb_twilight),
          _buildInfoCard('Bedtime', timeFormat.format(bedtime), Icons.bedtime),

          const Spacer(),
          const Text(
            'Editing goals is currently disabled for today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        ],
      ),
    );
  }

  // A helper widget to make the list look clean and uniform
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}