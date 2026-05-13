import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers.dart';
import '../../permission_helper.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId; // Used as index
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _selectedIndex = 1; // 0: Wait Time, 1: Detail/Edit
  
  // Controllers for wait time settings
  late TextEditingController _capacityCtrl;
  late TextEditingController _timeCtrl;

  @override
  void initState() {
    super.initState();
    _capacityCtrl = TextEditingController();
    _timeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _initWaitTimeControllers(GroupItem group) {
    if (_capacityCtrl.text.isEmpty && _timeCtrl.text.isEmpty) {
       _capacityCtrl.text = group.capacityPerEntry.toString();
       _timeCtrl.text = group.timePerEntryMinutes.toString();
    }
  }

  Future<void> _pickHeaderImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child('groups/${widget.groupId}/header_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(File(picked.path));
        }
        final downloadUrl = await storageRef.getDownloadURL();
        ref.read(groupsProvider.notifier).updateGroupHeaderImage(index, downloadUrl);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('画像のアップロードに失敗しました: $e')));
      }
    }
  }

  void _showAddPostDialog(int index) {
      final titleC = TextEditingController();
      final contentC = TextEditingController();
      XFile? localImageFile;
      
      showDialog(context: context, builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: const Text('新規投稿を作成'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleC, decoration: const InputDecoration(labelText: 'タイトル')),
                  TextField(controller: contentC, decoration: const InputDecoration(labelText: '内容', alignLabelWithHint: true), maxLines: 3),
                  const SizedBox(height: 16),
                  if (localImageFile != null)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: kIsWeb 
                           ? Image.network(localImageFile!.path, height: 100, fit: BoxFit.cover)
                           : Image.file(File(localImageFile!.path), height: 100, fit: BoxFit.cover),
                     ),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateBuilder(() {
                          localImageFile = picked;
                        });
                      }
                    }, 
                    icon: const Icon(Icons.image),
                    label: const Text('画像を追加')
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                ElevatedButton(
                  onPressed: () async {
                     if (titleC.text.isNotEmpty && contentC.text.isNotEmpty) {
                       String? downloadUrl;
                       if (localImageFile != null) {
                         try {
                           final storageRef = FirebaseStorage.instance.ref().child('groups/${widget.groupId}/posts/${DateTime.now().millisecondsSinceEpoch}.jpg');
                           if (kIsWeb) {
                             final bytes = await localImageFile!.readAsBytes();
                             await storageRef.putData(bytes);
                           } else {
                             await storageRef.putFile(File(localImageFile!.path));
                           }
                           downloadUrl = await storageRef.getDownloadURL();
                         } catch (e) {
                           // Ignore upload error for simplicity, or handle it
                         }
                       }
                       
                       ref.read(groupsProvider.notifier).addGroupPost(index, PostItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleC.text, content: contentC.text, timeString: 'たった今', imagePath: downloadUrl
                       ));
                       final groupName = ref.read(groupsProvider)[index].name;
                       ref.read(notificationsProvider.notifier).addNotification('$groupName のタイムラインが更新されました');
                       
                       final profile = ref.read(userProfileProvider);
                       final uid = ref.read(currentUserUidProvider) ?? '';
                       ref.read(auditLogProvider.notifier).logAction(
                         uid, profile.name, profile.avatarPath,
                         '「$groupName」に投稿「${titleC.text}」を追加',
                       );
                       if (context.mounted) Navigator.pop(ctx);
                     }
                  }, 
                  child: const Text('投稿')
                )
              ],
            );
          }
        );
      });
  }

  void _showEditTitleDescDialog(int index, GroupItem group) {
      final titleC = TextEditingController(text: group.name);
      final descC = TextEditingController(text: group.description);
      showDialog(context: context, builder: (ctx) {
        return AlertDialog(
          title: const Text('グループ情報を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'グループ名')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: '説明'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                 if (titleC.text.isNotEmpty) {
                   ref.read(groupsProvider.notifier).updateGroupTitle(index, titleC.text);
                   ref.read(groupsProvider.notifier).updateGroupDescription(index, descC.text);
                   // 監査ログ記録
                   final profile = ref.read(userProfileProvider);
                   final uid = ref.read(currentUserUidProvider) ?? '';
                   ref.read(auditLogProvider.notifier).logAction(
                     uid, profile.name, profile.avatarPath,
                     '「${titleC.text}」のグループ情報を編集',
                   );
                   Navigator.pop(ctx);
                 }
              }, 
              child: const Text('保存')
            )
          ],
        );
      });
  }

  void _showAddTimelineEventDialog(int index) {
      final titleC = TextEditingController();
      final timeC = TextEditingController();
      final descC = TextEditingController();
      
      showDialog(context: context, builder: (ctx) {
        return AlertDialog(
          title: const Text('タイムテーブルに追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'イベント名 (例: ダンスパフォーマンス)')),
              TextField(controller: timeC, decoration: const InputDecoration(labelText: '開始時間 (例: 14:30)')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: '詳細', alignLabelWithHint: true), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                 if (titleC.text.isNotEmpty && timeC.text.isNotEmpty) {
                   final event = EventItem(
                     id: DateTime.now().millisecondsSinceEpoch.toString(),
                     title: titleC.text,
                     date: DateTime.now(), // 簡略化のため現在日を使用
                     time: timeC.text,
                     organizer: ref.read(groupsProvider)[index].name,
                     description: descC.text,
                   );
                   ref.read(groupsProvider.notifier).addGroupTimelineEvent(index, event);
                   Navigator.pop(ctx);
                 }
              }, 
              child: const Text('追加')
            )
          ],
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final intIndex = int.tryParse(widget.groupId) ?? 0;
    final groups = ref.watch(groupsProvider);
    if (intIndex >= groups.length || intIndex < 0) {
      return Scaffold(appBar: AppBar(title: const Text('エラー')), body: const Center(child: Text('グループが見つかりません')));
    }
    final group = groups[intIndex];

    final myRole = ref.watch(currentEventRoleProvider);
    final myMember = ref.watch(eventMembersProvider)
        .where((m) => m.uid == ref.watch(currentUserUidProvider))
        .firstOrNull;
    final canEditThisGroup = PermissionHelper.canEditGroup(
      myRole, group.id, myMember?.assignedGroupId,
    );
    final canEditAll = PermissionHelper.canEditAll(myRole);
    _initWaitTimeControllers(group);

    ImageProvider? headerImage;
    if (group.headerImagePath != null) {
      if (kIsWeb) {
        headerImage = NetworkImage(group.headerImagePath!);
      } else {
        headerImage = FileImage(File(group.headerImagePath!));
      }
    } else {
      headerImage = const NetworkImage('https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=600&q=80');
    }

    Widget bodyContent = _selectedIndex == 0 || !canEditAll
        ? _buildDetailBody(canEditThisGroup, intIndex, group, headerImage)
        : _buildWaitTimeBody(intIndex, group);

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: bodyContent,
      floatingActionButton: (canEditThisGroup && _selectedIndex == 0)
          ? FloatingActionButton(
              onPressed: () => _showAddPostDialog(intIndex),
              backgroundColor: const Color(0xFF6B4EE6),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: canEditAll ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'ページ編集'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '待ち時間管理'),
        ],
      ) : null,
    );
  }

  Widget _buildWaitTimeBody(int index, GroupItem group) {
    int waitTimeMinutes = 0;
    if (group.capacityPerEntry > 0) {
      waitTimeMinutes = (group.timePerEntryMinutes * group.distributedTickets / group.capacityPerEntry).ceil();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('整理券・待ち時間システム', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('システム機能を有効にする'),
                    subtitle: const Text('ONにすると、ホーム画面のタグに「待ち時間あり」が適用されます'),
                    value: group.isWaitTimeSystemEnabled,
                    activeThumbColor: const Color(0xFFFF529F),
                    onChanged: (val) {
                      ref.read(groupsProvider.notifier).updateWaitTimeSettings(index, isEnabled: val);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (group.isWaitTimeSystemEnabled) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _capacityCtrl,
                      decoration: const InputDecoration(labelText: '1回あたりの入場人数 (n人)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _timeCtrl,
                      decoration: const InputDecoration(labelText: '1回あたりの所要時間 (a分)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final cap = int.tryParse(_capacityCtrl.text);
                          final time = int.tryParse(_timeCtrl.text);
                          if (cap != null && time != null) {
                             ref.read(groupsProvider.notifier).updateWaitTimeSettings(index, capacity: cap, timeMin: time);
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EE6), foregroundColor: Colors.white),
                        child: const Text('設定を保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFF7F9FC),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('現在の状況確認', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => ref.read(groupsProvider.notifier).decrementDistributedTickets(index),
                          icon: const Icon(Icons.remove_circle_outline, size: 32, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                             const Text('配布済み整理券', style: TextStyle(color: Colors.grey)),
                             Text('${group.distributedTickets}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => ref.read(groupsProvider.notifier).incrementDistributedTickets(index),
                          icon: const Icon(Icons.add_circle, size: 32, color: Color(0xFFFF529F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('算出待ち時間 (t):', style: TextStyle(fontSize: 18, color: Colors.black87)),
                        Text('約 $waitTimeMinutes 分', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF529F))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('計算式: (a × s) / n', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailBody(bool isOrganizer, int intIndex, GroupItem group, ImageProvider headerImage) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: headerImage,
                fit: BoxFit.cover,
              ),
            ),
            child: isOrganizer
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () => _pickHeaderImage(intIndex),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(group.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  if (isOrganizer)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF6B4EE6)),
                      onPressed: () => _showEditTitleDescDialog(intIndex, group),
                    )
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(group.description, style: const TextStyle(color: Colors.black87)),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              if (group.isWaitTimeSystemEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF529F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF529F).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFFF529F), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ただいまの待ち時間目安', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            Text(
                              '約 ${(group.capacityPerEntry > 0 ? (group.timePerEntryMinutes * group.distributedTickets / group.capacityPerEntry).ceil() : 0)} 分', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFFF529F))
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],

              const Text('タイムライン (お知らせ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (group.posts.isEmpty)
                 const Text(' まだ投稿はありません', style: TextStyle(color: Colors.grey))
              else
                 ...group.posts.map((post) => _buildPostCard(post)),
                 
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('展示タイムテーブル', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isOrganizer)
                    TextButton.icon(
                      onPressed: () => _showAddTimelineEventDialog(intIndex),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('追加'),
                    )
                ],
              ),
              const SizedBox(height: 16),

              if (group.timelineEvents.isEmpty)
                 const Text(' 予定はまだありません', style: TextStyle(color: Colors.grey))
              else
                 ...group.timelineEvents.map((event) => Card(
                   margin: const EdgeInsets.only(bottom: 8),
                   child: ListTile(
                     leading: Text(event.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4EE6))),
                     title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: event.description.isNotEmpty ? Text(event.description, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                     trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF6B4EE6)),
                     onTap: () {
                       showDialog(context: context, builder: (ctx) => AlertDialog(
                         title: const Text('マイタイムテーブルに追加'),
                         content: Text('「${event.title}」をあなたのタイムテーブルに追加しますか？'),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                           ElevatedButton(
                             onPressed: () {
                               ref.read(timetableProvider.notifier).addEvent(event);
                               Navigator.pop(ctx);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('追加しました！')));
                             }, 
                             child: const Text('追加する')
                           )
                         ],
                       ));
                     },
                   ),
                 )),

              const SizedBox(height: 80), // bottom padding for FAB
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(PostItem post) {
    ImageProvider? postImage;
    if (post.imagePath != null) {
       if (kIsWeb) {
         postImage = NetworkImage(post.imagePath!);
       } else {
         postImage = FileImage(File(post.imagePath!));
       }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF6B4EE6),
                  radius: 16,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(post.timeString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content),
            if (postImage != null) ...[
               const SizedBox(height: 12),
               ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(image: postImage),
               )
            ]
          ],
        ),
      ),
    );
  }
}
