import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class GlobalTimelineScreen extends ConsumerWidget {
  const GlobalTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);

    // Aggregate all posts from all groups
    // In a real app, this should be a DB query sorted by timestamp.
    // For MVP, we extract Posts, attach group info, and just show them.
    final allPosts = <Map<String, dynamic>>[];
    for (var g in groups) {
      for (var p in g.posts) {
        allPosts.add({
          'groupName': g.name,
          'post': p,
        });
      }
    }
    
    // Reverse so latest (assuming they are appended to top) are at top.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('全体タイムライン'),
      ),
      body: allPosts.isEmpty 
          ? const Center(child: Text('まだ投稿がありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: allPosts.length,
              itemBuilder: (context, index) {
                final item = allPosts[index];
                final groupName = item['groupName'] as String;
                final post = item['post'] as PostItem;
                return _buildGlobalPostCard(groupName, post);
              },
            ),
    );
  }

  Widget _buildGlobalPostCard(String groupName, PostItem post) {
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
                  child: Icon(Icons.group, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4EE6))),
                const SizedBox(width: 8),
                const Text('・', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(child: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
