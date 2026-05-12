import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      User? user;

      if (kIsWeb) {
        // Web: signInWithPopup を使う（最も確実な方法）
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        final UserCredential result =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        user = result.user;
      } else {
        // ネイティブ (Android/iOS/Windows): google_sign_in パッケージを使う
        await GoogleSignIn.instance.initialize();
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();
        final String? idToken = googleUser.authentication.idToken;
        if (idToken == null) throw Exception('IDトークンの取得に失敗しました。');
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final UserCredential result =
            await FirebaseAuth.instance.signInWithCredential(credential);
        user = result.user;
      }

      if (user != null && mounted) {
        ref.read(isGuestProvider.notifier).setGuest(false);
        ref.read(currentUserUidProvider.notifier).setUid(user.uid);
        ref.read(userProfileProvider.notifier).updateProfile(
          user.displayName ?? user.email ?? 'Googleユーザー',
          user.photoURL,
        );
        // イベント作成者がログインした場合は最高管理者として登録
        ref.read(eventMembersProvider.notifier).setCreator(
          user.uid,
          user.displayName ?? user.email ?? 'Googleユーザー',
          user.photoURL,
        );
        context.go('/account');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError('Googleログインに失敗しました。\n詳細: ${e.message}');
    } catch (e) {
      if (mounted) _showError('予期しないエラーが発生しました。\n詳細: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログインエラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.calendar_month,
                size: 80,
                color: Color(0xFF6B4EE6),
              ),
              const SizedBox(height: 24),
              Text(
                'イベントでつながる、\n新しい体験。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 48),
              // Googleログインボタン
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login, size: 20),
                      ),
                label: Text(_isLoading ? 'ログイン中...' : 'Googleでログイン'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // ゲストボタン
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        ref.read(isGuestProvider.notifier).setGuest(true);
                        context.go('/role_selection');
                      },
                icon: const Icon(Icons.person_outline),
                label: const Text('ゲストとして利用する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/role_selection'),
                child: const Text('デバッグ：スキップする',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
