import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class GroupSetupScreen extends ConsumerStatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  ConsumerState<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends ConsumerState<GroupSetupScreen> {
  final _newGroupController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('展示・グループを入力'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/setup/timetable');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: groups.length + 1,
                itemBuilder: (context, index) {
                  if (index == groups.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newGroupController,
                              decoration: const InputDecoration(
                                labelText: '新しいグループ名',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_newGroupController.text.isNotEmpty) {
                                ref.read(groupsProvider.notifier).addGroup(_newGroupController.text);
                                _newGroupController.clear();
                                FocusScope.of(context).unfocus();
                              }
                            },
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                    );
                  }

                  final group = groups[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.add, color: Color(0xFFFF529F)),
                                onPressed: () {
                                  _showAddTagDialog(context, index);
                                },
                              )
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: group.tags.map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: const Color(0xFF6B4EE6).withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Color(0xFF6B4EE6)),
                            )).toList(),
                          )
                        ],
                      ),
                    ),
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
                    context.go('/main');
                  },
                  child: const Text('ページを表示する'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, int index) {
    final tagCtrl = TextEditingController();
    
    // gather all existing tags across all groups
    final groups = ref.read(groupsProvider);
    final allTags = groups.expand((g) => g.tags).toSet().toList();

    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('属性タグを追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tagCtrl,
              decoration: const InputDecoration(hintText: '例：#お化け屋敷'),
            ),
            if (allTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('既存のタグから選択:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allTags.map((t) => ActionChip(
                  label: Text(t),
                  onPressed: () {
                    ref.read(groupsProvider.notifier).addTagToGroup(index, t);
                    Navigator.pop(ctx);
                  },
                )).toList(),
              )
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              if (tagCtrl.text.isNotEmpty) {
                var rawTitle = tagCtrl.text;
                if (!rawTitle.startsWith('#')) {
                  rawTitle = '#$rawTitle';
                }
                ref.read(groupsProvider.notifier).addTagToGroup(index, rawTitle);
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
