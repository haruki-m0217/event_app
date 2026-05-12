import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../providers.dart';
import '../permission_helper.dart';
import 'tabs/home_screen.dart';
import 'tabs/timetable_screen.dart';
import 'tabs/exhibition_list_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 1; // Default to Home
  bool _showNotification = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotification = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final eventName = ref.watch(eventNameProvider);
    final isOrganizer = role == UserRole.organizer;
    final isPublished = ref.watch(isEventPublishedProvider);
    final eventCode = ref.watch(eventCodeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final myEventRole = ref.watch(currentEventRoleProvider);
    final isSelf = true; // ドロワーは常に自分の表示
    final myRoleLabel = displayRoleName(myEventRole, isSelf);

    final tabs = [
      const TimetableScreen(),
      const HomeScreen(),
      const ExhibitionListScreen(),
    ];

    // Handle index out of bounds if switching from Organizer to Participant
    if (_currentIndex >= tabs.length) {
      _currentIndex = tabs.length - 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          )
        ],
      ),
      drawer: NavigationDrawer(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.push('/account'); // Navigate to account page
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(
                '${userProfile.name}${myEventRole != EventMemberRole.participant ? " ($myRoleLabel)" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('マイアカウント', style: TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: userProfile.avatarPath != null 
                    ? (kIsWeb ? NetworkImage(userProfile.avatarPath!) : FileImage(File(userProfile.avatarPath!))) as ImageProvider
                    : null,
                child: userProfile.avatarPath == null 
                    ? const Icon(Icons.person, color: Color(0xFF6B4EE6), size: 40)
                    : null,
              ),
              decoration: const BoxDecoration(color: Color(0xFF6B4EE6)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('タイムテーブル'),
            onTap: () {
               setState(() => _currentIndex = 0);
               Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('ホーム'),
            onTap: () {
               setState(() => _currentIndex = 1);
               Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('展示一覧'),
            onTap: () {
               setState(() => _currentIndex = 2);
               Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('全体タイムライン'),
            onTap: () {
               Navigator.pop(context);
               context.push('/global_timeline');
            },
          ),
          const Divider(),
          // Mode switch toggle
          ListTile(
            leading: Icon(isOrganizer ? Icons.admin_panel_settings : Icons.person),
            title: Text(isOrganizer ? '参加者画面へ切り替え' : '運営画面へ切り替え（権限を持つ場合）'),
            onTap: () {
              final newRole = isOrganizer ? UserRole.participant : UserRole.organizer;
              ref.read(userRoleProvider.notifier).setRole(newRole);
              Navigator.pop(context);
            },
          ),
          if (isOrganizer) ...[
             const Divider(),
             if (!isPublished)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.orange,
                     foregroundColor: Colors.white,
                   ),
                   icon: const Icon(Icons.rocket_launch),
                   label: const Text('イベントを公開する', style: TextStyle(fontWeight: FontWeight.bold)),
                   onPressed: () {
                     ref.read(isEventPublishedProvider.notifier).publish();
                     ref.read(eventCodeProvider.notifier).generateCode();
                     final newCode = ref.read(eventCodeProvider);
                     Navigator.pop(context);
                     showDialog(context: context, builder: (ctx) => AlertDialog(
                       title: const Text('公開完了！'),
                       content: Text('イベントが公開されました。\n以下の参加コードを参加者に共有してください。\n\n【 $newCode 】', style: const TextStyle(fontWeight: FontWeight.bold)),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                       ]
                     ));
                   },
                 ),
               )
             else
               ListTile(
                 tileColor: Colors.orange.withValues(alpha: 0.1),
                 leading: const Icon(Icons.check_circle, color: Colors.orange),
                 title: const Text('公開済み', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                 subtitle: Text('参加コード: $eventCode', style: const TextStyle(fontWeight: FontWeight.bold)),
                 trailing: IconButton(
                   icon: const Icon(Icons.edit, color: Colors.orange),
                   onPressed: () {
                     showDialog(context: context, builder: (ctx) {
                       final ctrl = TextEditingController(text: eventCode);
                       return AlertDialog(
                         title: const Text('参加コードの変更'),
                         content: TextField(
                           controller: ctrl,
                           decoration: const InputDecoration(labelText: '英数字で入力'),
                         ),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                           ElevatedButton(onPressed: () {
                             if (ctrl.text.isEmpty) return;
                             final success = ref.read(eventCodeProvider.notifier).trySetCustomCode(ctrl.text);
                             if (success) {
                               Navigator.pop(ctx);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('コードを変更しました')));
                             } else {
                               ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('このコードは既に使われています'), backgroundColor: Colors.red));
                             }
                           }, child: const Text('保存')),
                         ]
                       );
                     });
                   },
                 ),
               )
          ],
          if (role == UserRole.superAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.redAccent),
              title: const Text('最高管理者ダッシュボード', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin_dashboard');
              },
            ),
          ],
          // 運営・最高管理者向けメニュー
          if (PermissionHelper.canManageRoles(myEventRole)) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Color(0xFF6B4EE6)),
              title: const Text('メンバー管理', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/members');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF6B4EE6)),
              title: const Text('編集履歴', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/audit_log');
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_showNotification)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF6B4EE6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('新しいお知らせがあります', style: TextStyle(color: Colors.white)),
                ],
              ),
            ).animate().fade(duration: 500.ms).then(delay: 2.seconds).fadeOut(duration: 500.ms),
          
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.schedule), label: 'タイムテーブル'),
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '展示一覧'),
        ],
      ),
    );
  }
}
