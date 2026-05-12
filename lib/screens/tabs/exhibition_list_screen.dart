import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers.dart';
import '../../permission_helper.dart';

class ExhibitionListScreen extends ConsumerWidget {
  const ExhibitionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final myRole = ref.watch(currentEventRoleProvider);
    final myMember = ref.watch(eventMembersProvider).where(
      (m) => m.uid == ref.watch(currentUserUidProvider)
    ).firstOrNull;

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          
          ImageProvider? leadingImage;
          if (group.headerImagePath != null) {
            if (kIsWeb) {
               leadingImage = NetworkImage(group.headerImagePath!);
            } else {
               leadingImage = FileImage(File(group.headerImagePath!));
            }
          }

              // 編集可能かどうかチェック（展示代表は自グループのみ）
              final canEdit = PermissionHelper.canEditGroup(
                myRole,
                group.id,
                myMember?.assignedGroupId,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                      image: leadingImage != null ? DecorationImage(image: leadingImage, fit: BoxFit.cover) : null,
                    ),
                    child: leadingImage == null ? const Icon(Icons.image, color: Colors.grey) : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      if (canEdit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EE6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('編集可', style: TextStyle(fontSize: 11, color: Color(0xFF6B4EE6))),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 4,
                      children: group.tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF6B4EE6).withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: Color(0xFF6B4EE6)),
                      )).toList(),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    context.push('/group/$index');
                  },
                ),
              );
        },
      ),
      floatingActionButton: PermissionHelper.canEditAll(myRole) ? FloatingActionButton(
        onPressed: () {
          context.push('/setup/group'); 
        },
        backgroundColor: const Color(0xFF6B4EE6),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}
