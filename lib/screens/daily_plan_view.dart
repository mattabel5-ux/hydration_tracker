import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/hydration_provider.dart';
import 'notification_settings_dialog.dart';

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

    // Helper functions to show Time Pickers
    Future<void> selectFirstDrinkTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(firstDrink),
      );
      if (picked != null) {
        final now = DateTime.now();
        final newFirstDrink = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        ref.read(hydrationProvider.notifier).updateFirstDrink(newFirstDrink.millisecondsSinceEpoch);
      }
    }

    Future<void> selectBedtime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(bedtime),
      );
      if (picked != null) {
        final now = DateTime.now();

        // --- HUMAN BEDTIME LOGIC ---
        // If they pick a hour between 12 AM (0) and 4 AM (4), we force it to the NEXT calendar day
        // so the system doesn't immediately mark "Day Over" at midnight.
        int dayOffset = 0;
        if (picked.hour >= 0 && picked.hour < 5) {
          dayOffset = 1;
        }

        final newBedtime = DateTime(now.year, now.month, now.day + dayOffset, picked.hour, picked.minute);
        ref.read(hydrationProvider.notifier).updateBedtime(newBedtime.millisecondsSinceEpoch);
      }
    }

    // Helper function to show text dialogs for numbers
    Future<void> editNumberValue(String title, double currentValue, Function(double) onSave) async {
      final controller = TextEditingController(text: currentValue.toStringAsFixed(0));
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            // --- NEW: Highlights text on tap ---
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
            decoration: const InputDecoration(suffixText: 'oz'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null && val > 0) {
                  onSave(val);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

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
          const SizedBox(height: 24),
          const Text(
            'Tap any card below to update your settings for today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Interactive Data Cards
          _buildEditableCard(
            title: 'Daily Goal',
            value: '${dailyState.goalOz.toStringAsFixed(0)} oz',
            icon: Icons.flag,
            onTap: () => editNumberValue('Daily Goal', dailyState.goalOz, (val) {
              ref.read(hydrationProvider.notifier).updateGoal(val);
            }),
          ),
          _buildEditableCard(
            title: 'Bottle Size',
            value: '${dailyState.bottleSize.toStringAsFixed(0)} oz',
            icon: Icons.local_drink,
            onTap: () => editNumberValue('Bottle Size', dailyState.bottleSize, (val) {
              ref.read(hydrationProvider.notifier).updateBottleSize(val);
            }),
          ),
          _buildEditableCard(
            title: 'First Drink',
            value: timeFormat.format(firstDrink),
            icon: Icons.wb_twilight,
            onTap: selectFirstDrinkTime,
          ),
          _buildEditableCard(
            title: 'Bedtime',
            value: timeFormat.format(bedtime),
            icon: Icons.bedtime,
            onTap: selectBedtime,
          ),
          _buildEditableCard(
            title: 'Notifications',
            value: '${dailyState.notificationIntervalMinutes} min',
            icon: Icons.notifications_active,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const NotificationSettingsDialog(),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}