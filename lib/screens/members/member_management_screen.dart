import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../permission_helper.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(eventMembersProvider);
    final currentUid = ref.watch(currentUserUidProvider);
    final myRole = ref.watch(currentEventRoleProvider);
    final groups = ref.watch(groupsProvider);

    final filtered = _searchQuery.isEmpty
        ? members
        : members
            .where((m) => m.displayName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('メンバー管理'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ユーザー名で検索...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('メンバーがいません',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('参加コードを共有して、メンバーを招待しましょう',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final member = filtered[index];
                final isSelf = member.uid == currentUid;
                final roleName = displayRoleName(member.role, isSelf);
                final roleColor = _roleColor(member.role, isSelf);
                final assignedGroup = member.assignedGroupId != null
                    ? groups
                        .where((g) => g.id == member.assignedGroupId)
                        .firstOrNull
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundImage: member.photoUrl != null
                          ? (kIsWeb
                              ? NetworkImage(member.photoUrl!)
                              : FileImage(File(member.photoUrl!)))
                              as ImageProvider
                          : null,
                      backgroundColor: const Color(0xFF6B4EE6),
                      child: member.photoUrl == null
                          ? Text(
                              member.displayName.isNotEmpty
                                  ? member.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${member.displayName}${isSelf ? " (あなた)" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: roleColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            roleName,
                            style: TextStyle(
                                color: roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: assignedGroup != null
                        ? Text('担当: ${assignedGroup.name}',
                            style: const TextStyle(color: Colors.grey))
                        : null,
                    trailing: (PermissionHelper.canManageRoles(myRole) &&
                            !isSelf &&
                            member.role != EventMemberRole.superAdmin)
                        ? IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF6B4EE6)),
                            onPressed: () =>
                                _showRoleEditDialog(context, member, groups),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Color _roleColor(EventMemberRole role, bool isSelf) {
    switch (role) {
      case EventMemberRole.superAdmin:
        return isSelf ? Colors.red : const Color(0xFF6B4EE6);
      case EventMemberRole.staff:
        return const Color(0xFF6B4EE6);
      case EventMemberRole.exhibitionLead:
        return Colors.teal;
      case EventMemberRole.participant:
        return Colors.grey;
    }
  }

  void _showRoleEditDialog(
      BuildContext context, EventMember member, List<GroupItem> groups) {
    EventMemberRole selectedRole = member.role;
    String? selectedGroupId = member.assignedGroupId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('${member.displayName} の権限を変更'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('権限:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // 役割選択チップ
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('運営'),
                      selected: selectedRole == EventMemberRole.staff,
                      selectedColor:
                          const Color(0xFF6B4EE6).withValues(alpha: 0.2),
                      onSelected: (_) => setDialogState(() {
                        selectedRole = EventMemberRole.staff;
                        selectedGroupId = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('展示代表'),
                      selected: selectedRole == EventMemberRole.exhibitionLead,
                      selectedColor: Colors.teal.withValues(alpha: 0.2),
                      onSelected: (_) => setDialogState(
                          () => selectedRole = EventMemberRole.exhibitionLead),
                    ),
                    ChoiceChip(
                      label: const Text('参加者'),
                      selected: selectedRole == EventMemberRole.participant,
                      onSelected: (_) => setDialogState(() {
                        selectedRole = EventMemberRole.participant;
                        selectedGroupId = null;
                      }),
                    ),
                  ],
                ),
                // 展示代表の場合はグループ選択
                if (selectedRole == EventMemberRole.exhibitionLead) ...[
                  const SizedBox(height: 16),
                  const Text('担当グループ:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (groups.isEmpty)
                    const Text('グループがありません',
                        style: TextStyle(color: Colors.grey))
                  else
                    DropdownButton<String>(
                      value: selectedGroupId,
                      isExpanded: true,
                      hint: const Text('グループを選択'),
                      items: groups
                          .map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedGroupId = v),
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('キャンセル')),
              ElevatedButton(
                onPressed: () {
                  if (selectedRole == EventMemberRole.exhibitionLead &&
                      selectedGroupId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('展示代表は担当グループを選択してください'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }
                  ref.read(eventMembersProvider.notifier).updateRole(
                        member.uid,
                        selectedRole,
                        assignedGroupId: selectedGroupId,
                      );
                  // 監査ログ記録
                  final myProfile = ref.read(userProfileProvider);
                  final myUid = ref.read(currentUserUidProvider) ?? '';
                  ref.read(auditLogProvider.notifier).logAction(
                        myUid,
                        myProfile.name,
                        myProfile.avatarPath,
                        '${member.displayName} の権限を「${displayRoleName(selectedRole, false)}」に変更',
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.displayName} の権限を更新しました')),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}
