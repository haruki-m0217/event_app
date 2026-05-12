import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class TimetableSetupScreen extends ConsumerStatefulWidget {
  const TimetableSetupScreen({super.key});

  @override
  ConsumerState<TimetableSetupScreen> createState() => _TimetableSetupScreenState();
}

class _TimetableSetupScreenState extends ConsumerState<TimetableSetupScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムテーブルを入力'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/setup/event_name');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: timetable.length + 1,
                itemBuilder: (context, index) {
                  if (index == timetable.length) {
                    return _buildAddEventCard();
                  }

                  final item = timetable[index];
                  final dateStr = '${item.date.month}月${item.date.day}日 ${item.time}';

                  return Column(
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6B4EE6))),
                                  const Spacer(),
                                  Text('主催: ${item.organizer}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(item.description, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      // Connect to next card
                      if (index < timetable.length)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 2, height: 40, color: const Color(0xFFE2E8F0)),
                            InkWell(
                              onTap: () {
                                 _showInsertDialog(context, index + 1);
                              },
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.add_circle, color: Color(0xFFFF529F)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/setup/group');
                  },
                  child: const Text('次へ'),
                ),
              ),
            )
          ],
        ),
      ),
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

  void _showInsertDialog(BuildContext context, int index) {
      final titleC = TextEditingController();
      final dateC = TextEditingController();
      final timeC = TextEditingController();
      DateTime insertDate = _selectedDate;

      showDialog(context: context, builder: (ctx) {
        return AlertDialog(
          title: const Text('イベントを中間に挿入'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                   Expanded(
                     child: GestureDetector(
                       onTap: () async {
                         final date = await showDatePicker(context: context, initialDate: insertDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                         if (date != null) {
                           insertDate = date;
                           dateC.text = '${date.year}/${date.month}/${date.day}';
                         }
                       },
                       child: AbsorbPointer(child: TextField(controller: dateC, decoration: const InputDecoration(labelText: '日付'))),
                     )
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: GestureDetector(
                       onTap: () async {
                         final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                         if (time != null) {
                           final hour = time.hour.toString().padLeft(2, '0');
                           final min = time.minute.toString().padLeft(2, '0');
                           timeC.text = '$hour:$min';
                         }
                       },
                       child: AbsorbPointer(child: TextField(controller: timeC, decoration: const InputDecoration(labelText: '時刻'))),
                     )
                   ),
                ]
              ),
              const SizedBox(height: 8),
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'イベント名')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                 if (titleC.text.isNotEmpty && timeC.text.isNotEmpty && dateC.text.isNotEmpty) {
                   ref.read(timetableProvider.notifier).insertEvent(index, EventItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleC.text, date: insertDate, time: timeC.text, organizer: '未定', description: ''
                   ));
                   Navigator.pop(ctx);
                 }
              }, 
              child: const Text('追加')
            )
          ],
        );
      });
  }
}
