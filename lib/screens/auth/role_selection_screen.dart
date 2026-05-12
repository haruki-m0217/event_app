import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方は？'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            if (!isGuest) ...[
              _RoleCard(
                icon: Icons.edit,
                title: 'イベントを作成',
                description: '新しいイベントを立ち上げ、管理します。',
                onTap: () {
                  ref.read(userRoleProvider.notifier).setRole(UserRole.organizer);
                  context.go('/setup/event_name');
                },
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.qr_code_scanner,
              title: '参加コードから参加',
              description: '公開されているイベントコードを入力します。',
              onTap: () {
                 showDialog(context: context, builder: (ctx) {
                   final ctrl = TextEditingController();
                   return AlertDialog(
                     title: const Text('イベント参加'),
                     content: TextField(
                       controller: ctrl,
                       decoration: const InputDecoration(labelText: '参加コード (例: GAKUSAI-2026)')
                     ),
                     actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                        ElevatedButton(
                           onPressed: () {
                              if (ctrl.text.isNotEmpty) {
                                final globalCode = ref.read(eventCodeProvider);
                                final globalName = ref.read(eventNameProvider);
                                
                                String joinTitle = 'Unknown Event';
                                if (ctrl.text == globalCode && globalCode != null) {
                                  joinTitle = globalName;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('参加コードが見つかりません')),
                                  );
                                  return; // Reject 
                                }

                                // Update joined list
                                ref.read(myJoinedEventsProvider.notifier).addEvent(joinTitle);
                                // Set event name
                                ref.read(eventNameProvider.notifier).setName(joinTitle);
                                // Set role
                                ref.read(userRoleProvider.notifier).setRole(UserRole.participant);

                                Navigator.pop(ctx);
                                context.go('/main');
                              }
                           },
                           child: const Text('参加する')
                        )
                     ]
                   );
                 });
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
