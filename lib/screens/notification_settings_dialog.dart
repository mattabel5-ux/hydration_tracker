import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hydration_provider.dart';

class NotificationSettingsDialog extends ConsumerStatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  ConsumerState<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends ConsumerState<NotificationSettingsDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  String _selectedType = 'standard';

  @override
  void initState() {
    super.initState();
    final currentData = ref.read(hydrationProvider);
    final totalMinutes = currentData?.notificationIntervalMinutes ?? 60;

    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;

    _hoursController = TextEditingController(text: hours.toString());
    _minutesController = TextEditingController(text: minutes.toString());
    _selectedType = currentData?.notificationType ?? 'standard';
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Remind me every:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    // Highlights text on tap
                    onTap: () {
                      _hoursController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _hoursController.text.length,
                      );
                    },
                    decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    // Highlights text on tap
                    onTap: () {
                      _minutesController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _minutesController.text.length,
                      );
                    },
                    decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Alert Style:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Standard Banner'),
              subtitle: const Text('Default drop-down notification'),
              value: 'standard',
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Full Screen (Urgent)'),
              subtitle: const Text('Requires manual dismissal (Android)'),
              value: 'fullscreen',
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final int hours = int.tryParse(_hoursController.text) ?? 0;
            final int minutes = int.tryParse(_minutesController.text) ?? 0;
            final int totalMinutes = (hours * 60) + minutes;

            if (totalMinutes > 0) {
              ref.read(hydrationProvider.notifier)
                  .updateNotificationSettings(totalMinutes, _selectedType);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}