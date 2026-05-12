import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class EventNameScreen extends ConsumerStatefulWidget {
  const EventNameScreen({super.key});

  @override
  ConsumerState<EventNameScreen> createState() => _EventNameScreenState();
}

class _EventNameScreenState extends ConsumerState<EventNameScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default or existing name
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _controller.text = ref.read(eventNameProvider);
       if (_controller.text == '新しいイベント') {
         _controller.text = ''; // Leave it blank on first start
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントを作成'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role_selection');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('イベント名を入力', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text('※後から変更できます', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '例：青葉祭 2026',
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _controller.text.isEmpty
                      ? null
                      : () {
                          // Save to riverpod
                          ref.read(eventNameProvider.notifier).setName(_controller.text);
                          // Use push instead of go to allow back button history
                          context.push('/setup/timetable');
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
}
