import 'dart:io';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdEvents = ref.watch(myCreatedEventsProvider);
    final joinedEvents = ref.watch(myJoinedEventsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイアカウント'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.go('/login');
            },
          )
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
                  const Text('testuser@gmail.com', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Created Events
            const Text('自分が管理しているイベント', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (createdEvents.isEmpty)
              const Text('作成したイベントはありません。', style: TextStyle(color: Colors.grey))
            else
              ...createdEvents.map((title) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF6B4EE6)),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ref.read(eventNameProvider.notifier).setName(title.replaceAll(' (主催中)', ''));
                    ref.read(userRoleProvider.notifier).setRole(UserRole.organizer);
                    context.go('/main'); 
                  },
                ),
              )),
              
            const SizedBox(height: 32),
            
            // Joined Events
            const Text('参加しているイベント', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (joinedEvents.isEmpty)
              const Text('参加しているイベントはありません。', style: TextStyle(color: Colors.grey))
            else
              ...joinedEvents.map((title) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ListTile(
                  title: Text(title),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ref.read(eventNameProvider.notifier).setName(title);
                    ref.read(userRoleProvider.notifier).setRole(UserRole.participant);
                    context.go('/main'); 
                  },
                ),
              )),
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
