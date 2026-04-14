import 'package:flutter/material.dart';

import '../models/copy_workout_request.dart';
import '../theme/app_density.dart';

class CopyWorkoutSheet extends StatefulWidget {
  const CopyWorkoutSheet({
    super.key,
    required this.initialName,
  });

  final String initialName;

  @override
  State<CopyWorkoutSheet> createState() => _CopyWorkoutSheetState();
}

class _CopyWorkoutSheetState extends State<CopyWorkoutSheet> {
  late DateTime _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateUtils.dateOnly(now);
    _start = TimeOfDay(hour: now.hour, minute: now.minute);
    final defaultEnd = now.add(const Duration(hours: 1));
    _end = TimeOfDay(hour: defaultEnd.hour, minute: defaultEnd.minute);
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDensity.space(18),
          AppDensity.space(14),
          AppDensity.space(18),
          AppDensity.space(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppDensity.space(36),
                height: AppDensity.space(4),
                decoration: BoxDecoration(
                  color: colors.outlineVariant.withOpacity(0.9),
                  borderRadius: AppDensity.circular(999),
                ),
              ),
            ),
            SizedBox(height: AppDensity.space(16)),
            Text(
              'Copy workout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: AppDensity.space(6)),
            Text(
              'Create a new session from this workout with all exercises, set values, notes, and structure carried over.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppDensity.space(16)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppDensity.space(12)),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Day',
                    value: _formatDay(_day),
                    onTap: _pickDay,
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.schedule_rounded,
                    label: 'Start',
                    value: _start.format(context),
                    onTap: _pickStart,
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.flag_rounded,
                    label: 'End',
                    value: _end.format(context),
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDensity.space(18)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Copy workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _day,
    );
    if (picked == null || !mounted) return;
    setState(() => _day = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start,
    );
    if (picked == null || !mounted) return;
    setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
    );
    if (picked == null || !mounted) return;
    setState(() => _end = picked);
  }

  void _submit() {
    final start = _merge(_day, _start);
    final end = _merge(_day, _end);
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      return;
    }

    Navigator.pop(
      context,
      CopyWorkoutRequest(
        sessionName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        startTime: start,
        endTime: end,
      ),
    );
  }

  DateTime _merge(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  String _formatDay(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDensity.circular(16),
      child: Container(
        padding: EdgeInsets.all(AppDensity.space(12)),
        decoration: BoxDecoration(
          borderRadius: AppDensity.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            SizedBox(height: AppDensity.space(8)),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppDensity.space(4)),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
