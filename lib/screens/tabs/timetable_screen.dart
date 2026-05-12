import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../permission_helper.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int? _expandedIndex;

  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _organizerController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _selectedDate = date;
      _dateController.text = '${date.year}/${date.month}/${date.day}';
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final min = time.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetable = ref.watch(timetableProvider);
    final activeReminders = ref.watch(activeRemindersProvider);
    final myRole = ref.watch(currentEventRoleProvider);
    final canPost = PermissionHelper.canPostTimetable(myRole);

    if (timetable.isEmpty && !canPost) {
      return const Center(child: Text('イベントがありません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: timetable.length + (canPost ? 1 : 0),
      itemBuilder: (context, index) {
        if (canPost && index == timetable.length) {
          return _buildAddEventCard();
        }

        final item = timetable[index];
        final isExpanded = _expandedIndex == index;
        final isReminderOn = activeReminders.contains(item);
        final dateStr = '${item.date.month}月${item.date.day}日 ${item.time}';

        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6B4EE6))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Text('主催: ${item.organizer}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(item.description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('リマインダー'),
                              const Spacer(),
                              Switch(
                                value: isReminderOn, 
                                activeThumbColor: const Color(0xFFFF529F),
                                onChanged: (v) {
                                  ref.read(activeRemindersProvider.notifier).toggleReminder(item);
                                }
                              )
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Middle connecting line between items OR before the add card
            if (index < timetable.length - (canPost ? 0 : 1))
              Container(width: 2, height: 40, color: const Color(0xFFE2E8F0)),
          ],
        );
      },
    );
  }

  Widget _buildAddEventCard() {
    return Card(
      color: const Color(0xFFF7F9FC),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF38B2AC), width: 2, style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF38B2AC)),
                SizedBox(width: 8),
                Text('この下にイベントを追加', style: TextStyle(color: Color(0xFF38B2AC), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'イベント名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _pickDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(labelText: '日付', border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _pickTime(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(labelText: '時刻', border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _organizerController,
                    decoration: const InputDecoration(labelText: '主催者', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '概要', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty && _timeController.text.isNotEmpty && _dateController.text.isNotEmpty) {
                    ref.read(timetableProvider.notifier).addEvent(
                      EventItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        date: _selectedDate,
                        time: _timeController.text,
                        organizer: _organizerController.text,
                        description: _descController.text,
                      )
                    );
                    _titleController.clear();
                    _timeController.clear();
                    _organizerController.clear();
                    _descController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38B2AC)),
                child: const Text('追加する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
