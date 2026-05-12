import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedInUsers = ref.watch(loggedInUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('最高管理者ダッシュボード'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              color: Color(0xFFFEE2E2),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'この画面は最高管理者 (Super Admin) のみに表示されます。システム全体の管理や監視を行えます。',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('現在ログイン中のユーザー', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: loggedInUsers.length,
                itemBuilder: (context, index) {
                  final userStr = loggedInUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(userStr),
                      trailing: IconButton(
                        icon: const Icon(Icons.exit_to_app, color: Colors.red),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userStr を強制ログアウトしました (デモ)')));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
