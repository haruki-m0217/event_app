import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers.dart';

class AccountDashboardScreen extends ConsumerWidget {
  const AccountDashboardScreen({super.key});

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final current = ref.read(userProfileProvider);
      ref.read(userProfileProvider.notifier).updateProfile(current.name, picked.path);
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(userProfileProvider);
    final ctrl = TextEditingController(text: current.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('プロフィールを編集'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'ユーザー名'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
        ElevatedButton(onPressed: () {
          if (ctrl.text.isNotEmpty) {
            ref.read(userProfileProvider.notifier).updateProfile(ctrl.text, current.avatarPath);
            Navigator.pop(ctx);
          }
        }, child: const Text('保存')),
      ],
    ));
  }

  Widget _buildRoleBadge(EventMemberRole role, bool isGuest) {
    if (isGuest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text('ゲスト', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    final (color, icon, label) = switch (role) {
      EventMemberRole.superAdmin => (Colors.red, Icons.security, '最高責任者'),
      EventMemberRole.staff     => (const Color(0xFF6B4EE6), Icons.admin_panel_settings, '運営スタッフ'),
      EventMemberRole.exhibitionLead => (Colors.teal, Icons.people, '展示係'),
      _                         => (Colors.blueGrey, Icons.badge, '参加者'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    ref.read(isGuestProvider.notifier).setGuest(true);
    ref.read(currentUserUidProvider.notifier).setUid('');
    ref.read(userRoleProvider.notifier).setRole(UserRole.participant);
    if (context.mounted) context.go('/main');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final myEventRole = ref.watch(currentEventRoleProvider);
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイアカウント'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ログアウト',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('ログアウトしますか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ログアウト')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await _handleLogout(context, ref);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickAvatar(context, ref),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: profile.avatarPath != null 
                             ? (kIsWeb ? NetworkImage(profile.avatarPath!) : FileImage(File(profile.avatarPath!))) as ImageProvider
                             : null,
                          child: profile.avatarPath == null 
                             ? const Icon(Icons.person, size: 40, color: Color(0xFF6B4EE6))
                             : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF6B4EE6), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          )
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profile.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        onPressed: () => _showEditProfileDialog(context, ref),
                      )
                    ],
                  ),
                  Text(FirebaseAuth.instance.currentUser?.email ?? 'ゲスト', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  // 権限バッジ
                  _buildRoleBadge(myEventRole, isGuest),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // 権限追加セクション (Moved to top)
            const Text('運営・展示係の方へ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF6B4EE6).withValues(alpha: 0.05),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF6B4EE6)),
                borderRadius: BorderRadius.circular(12)
              ),
              child: ListTile(
                leading: const Icon(Icons.key, color: Color(0xFF6B4EE6)),
                title: const Text('権限追加用パスコードを入力', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4EE6))),
                onTap: () {
                  showDialog(context: context, builder: (ctx) {
                    final ctrl = TextEditingController();
                    bool isError = false;
                    return StatefulBuilder(builder: (ctx, setState) {
                      return AlertDialog(
                        title: const Text('パスコード入力'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('担当者から共有されたパスコードを入力してください。'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: ctrl,
                              decoration: InputDecoration(
                                labelText: 'パスコード',
                                errorText: isError ? '無効なパスコードです' : null,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                          ElevatedButton(onPressed: () {
                            final code = ctrl.text.trim();
                            EventMemberRole? newRole;
                            if (code == 'SUPER2026') {
                              newRole = EventMemberRole.superAdmin;
                            } else if (code == 'STAFF2026') {
                              newRole = EventMemberRole.staff;
                            } else if (code == 'LEAD2026') {
                              newRole = EventMemberRole.exhibitionLead;
                            }
                            
                            if (newRole != null) {
                              final uid = ref.read(currentUserUidProvider);
                              if (uid != null) {
                                ref.read(eventMembersProvider.notifier).updateRole(uid, newRole);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${displayRoleName(newRole, true)}の権限を追加しました！')));
                                Navigator.pop(ctx);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログイン情報がありません。')));
                              }
                            } else {
                              setState(() => isError = true);
                            }
                          }, child: const Text('追加')),
                        ],
                      );
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/role_selection');
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新しいイベント', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6B4EE6),
      ),
    );
  }
}
