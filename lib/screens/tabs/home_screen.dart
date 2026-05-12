import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentReminderIndex = 0;
  String _selectedFloorTag = '全体';
  bool _isFloorMenuExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openMapViewer(String? imagePath) {
    if (imagePath == null) return;
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          extendBodyBehindAppBar: true,
          body: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: kIsWeb 
                ? Image.network(imagePath) 
                : Image.file(File(imagePath)),
            ),
          ),
        );
      }
    );
  }

  Future<void> _pickImageForFloor(String floorTag) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(campusMapProvider.notifier).setImageForFloor(floorTag, picked.path);
    }
  }

  void _showMapSettingsDialog(CampusMapState mapState) {
    int floors = mapState.totalFloors;
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (context, setState) {
        final List<String> tags = ['全体'];
        for (int i = 1; i <= floors; i++) {
          tags.add('$i階');
        }

        return AlertDialog(
          title: const Text('マップ設定'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('総階数:'),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                          if (floors > 0) setState(() => floors--);
                        }),
                        Text('$floors', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                          if (floors < 10) setState(() => floors++);
                        }),
                      ],
                    )
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final hasImage = ref.watch(campusMapProvider).floorImages.containsKey(tag);
                      return ListTile(
                        title: Text(tag),
                        subtitle: Text(hasImage ? '画像設定済み' : '未設定', style: TextStyle(color: hasImage ? Colors.green : Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed: () => _pickImageForFloor(tag),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
            ElevatedButton(onPressed: () {
              ref.read(campusMapProvider.notifier).setTotalFloors(floors);
              Navigator.pop(ctx);
            }, child: const Text('完了'))
          ],
        );
      });
    });
  }

  Future<void> _addSurvey(String title, String url) async {
    String finalTitle = title;
    // If title is empty, try fetching from the URL
    if (finalTitle.isEmpty) {
      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final regex = RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true);
          final match = regex.firstMatch(response.body);
          if (match != null && match.groupCount > 0) {
            final fetchedTitle = match.group(1)?.trim();
            if (fetchedTitle != null && fetchedTitle.isNotEmpty && !fetchedTitle.contains('Google Forms')) {
              finalTitle = fetchedTitle;
            } else {
              finalTitle = 'アンケート (${uri.host})';
            }
          } else {
            finalTitle = 'アンケート (${uri.host})';
          }
        } else {
          finalTitle = 'アンケートリンク (${uri.host})';
        }
      } catch (e) {
        // Fallback to URL if network request fails (e.g. CORS on web)
        final uri = Uri.tryParse(url);
        finalTitle = uri?.host != null ? 'アンケート (${uri!.host})' : 'アンケートリンク';
      }
    }
    
    if (finalTitle.isEmpty) finalTitle = url;

    ref.read(surveysProvider.notifier).addSurvey(SurveyItem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: finalTitle, url: url));
  }

  void _addSurveyDialog() {
     final urlCtrl = TextEditingController();
     showDialog(context: context, builder: (ctx) {
        return AlertDialog(
           title: const Text('アンケートを追加'),
           content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 const Text('URLを入力すると、タイトルは自動で取得されます。', style: TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 8),
                 TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL (Google Form等)')),
              ]
           ),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
              ElevatedButton(onPressed: () async {
                 if (urlCtrl.text.isNotEmpty) {
                    final u = urlCtrl.text;
                    Navigator.pop(ctx);
                    await _addSurvey('', u);
                 }
              }, child: const Text('追加')),
           ]
        );
     });
  }

  Widget _buildGroupList(List<GroupItem> displayGroups, List<GroupItem> allGroups, String? activeTag) {
    if (displayGroups.isEmpty) {
      return const Padding(
         padding: EdgeInsets.all(16.0), 
         child: Text('表示できる展示がありません'),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayGroups.length,
        itemBuilder: (context, index) {
          final group = displayGroups[index];
          final isFilteredOut = activeTag != null && (
            activeTag == '待ち時間あり' 
              ? !group.isWaitTimeSystemEnabled 
              : !group.tags.contains(activeTag)
          );

          int waitTimeMinutes = 0;
          if (group.isWaitTimeSystemEnabled && group.capacityPerEntry > 0) {
            waitTimeMinutes = (group.timePerEntryMinutes * group.distributedTickets / group.capacityPerEntry).ceil();
          }

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

          Widget cardContent = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    image: DecorationImage(image: headerImage, fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...group.tags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(t, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            )),
                            if (group.isWaitTimeSystemEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF529F).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFF529F).withValues(alpha: 0.5)),
                                ),
                                child: Text('待ち時間あり (約$waitTimeMinutes分)', style: const TextStyle(fontSize: 12, color: Color(0xFFFF529F), fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const Spacer(),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.arrow_forward, color: Colors.grey),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isFilteredOut) {
            cardContent = Opacity(
              opacity: 0.4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  child: cardContent,
                ),
              ),
            );
          }

          final realIndex = allGroups.indexOf(group);

          return GestureDetector(
            onTap: () {
              context.push('/group/$realIndex');
            },
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              child: cardContent,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrganizer = ref.watch(userRoleProvider) == UserRole.organizer;
    final groups = ref.watch(groupsProvider);
    final campusMap = ref.watch(campusMapProvider);
    final activeReminders = ref.watch(activeRemindersProvider);
    final activeTag = ref.watch(activeFilterTagProvider);
    final surveys = ref.watch(surveysProvider);

    DecorationImage? mapDecoration;
    final mapImagePath = campusMap.floorImages[_selectedFloorTag] ?? campusMap.floorImages['全体'];
    if (mapImagePath != null) {
      if (kIsWeb) {
        mapDecoration = DecorationImage(image: NetworkImage(mapImagePath), fit: BoxFit.cover);
      } else {
        mapDecoration = DecorationImage(image: FileImage(File(mapImagePath)), fit: BoxFit.cover);
      }
    } else {
      mapDecoration = const DecorationImage(
        image: NetworkImage('https://images.unsplash.com/photo-1576085898323-218337e3e43c?auto=format&fit=crop&w=600&q=80'),
        fit: BoxFit.cover,
      );
    }

    final allTags = ['展示', '1年', '2年', '3年', '待ち時間あり'];

    // Sort groups for the ALL list
    final sortedGroups = [...groups];
    if (activeTag != null) {
      sortedGroups.sort((a, b) {
        final aMatch = activeTag == '待ち時間あり' ? a.isWaitTimeSystemEnabled : a.tags.contains(activeTag);
        final bMatch = activeTag == '待ち時間あり' ? b.isWaitTimeSystemEnabled : b.tags.contains(activeTag);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });
    }

    // Wait time groups for the specialized list
    final waitTimeGroups = groups.where((g) => g.isWaitTimeSystemEnabled).toList();

    // Reminder sorting
    final sortedReminders = [...activeReminders];
    if (sortedReminders.isNotEmpty) {
      sortedReminders.sort((a, b) => a.absoluteDateTime.compareTo(b.absoluteDateTime));
    }

    EventItem? currentReminder;
    if (sortedReminders.isNotEmpty) {
      final safeIdx = _currentReminderIndex % sortedReminders.length;
      currentReminder = sortedReminders[safeIdx];
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section
          GestureDetector(
            onTap: () {
              final mapImagePath = campusMap.floorImages[_selectedFloorTag] ?? campusMap.floorImages['全体'];
              _openMapViewer(mapImagePath);
            },
            child: Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
                image: mapDecoration,
              ),
              child: Stack(
                children: [
                  // Organizer Settings Button (Bottom Left)
                  if (isOrganizer)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => _showMapSettingsDialog(campusMap),
                        ),
                      ),
                    ),
                  // Expandable Floor Selector (Speed Dial at Bottom Right)
                  if (campusMap.totalFloors > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizeTransition(
                            sizeFactor: _expandAnimation,
                            axis: Axis.vertical,
                            axisAlignment: 1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: ['全体', ...List.generate(campusMap.totalFloors, (i) => '${i + 1}階')].reversed.map((tag) {
                                if (tag == _selectedFloorTag) return const SizedBox.shrink(); // Hide current
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                                  child: FloatingActionButton.small(
                                    heroTag: 'map_floor_$tag',
                                    backgroundColor: Colors.white,
                                    onPressed: () {
                                      setState(() {
                                        _selectedFloorTag = tag;
                                        _isFloorMenuExpanded = false;
                                      });
                                      _animationController.reverse();
                                    },
                                    child: Text(tag == '全体' ? 'ALL' : tag.replaceAll('階', 'F'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          FloatingActionButton(
                            heroTag: 'map_floor_main',
                            backgroundColor: const Color(0xFF6B4EE6),
                            onPressed: () {
                              setState(() {
                                _isFloorMenuExpanded = !_isFloorMenuExpanded;
                              });
                              if (_isFloorMenuExpanded) {
                                _animationController.forward();
                              } else {
                                _animationController.reverse();
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                              child: _isFloorMenuExpanded 
                                  ? const Icon(Icons.close, color: Colors.white, key: ValueKey('close_icon'))
                                  : Text(_selectedFloorTag == '全体' ? 'ALL' : _selectedFloorTag.replaceAll('階', 'F'), 
                                         key: const ValueKey('floor_text'), 
                                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          
          // Reminder Section
          if (currentReminder != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentReminderIndex++;
                  });
                },
                child: Card(
                  color: const Color(0xFFF7F9FC),
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(20),
                     side: const BorderSide(color: Color(0xFFFF529F), width: 1.5)
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.timer, color: Color(0xFFFF529F)),
                    title: Text(currentReminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('開始時刻: ${currentReminder.time}'),
                    trailing: sortedReminders.length > 1 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(_currentReminderIndex % sortedReminders.length) + 1}/${sortedReminders.length}', style: const TextStyle(color: Color(0xFFFF529F), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF529F)),
                            ]
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (sortedReminders.length > 1) 
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text('タップして次のリマインダーを確認', style: TextStyle(color: Colors.grey, fontSize: 11)),
              )
          ],
          
          // Attributes (Tags)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: allTags.map((t) {
                final isSelected = t == activeTag;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(activeFilterTagProvider.notifier).setTag(selected ? t : null);
                  },
                  selectedColor: const Color(0xFF6B4EE6).withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: isSelected ? const Color(0xFF6B4EE6) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                );
              }).toList(),
            ),
          ),

          // All Group Cards
          _buildGroupList(sortedGroups, groups, activeTag),

          // Wait Time Only Section
          if (waitTimeGroups.isNotEmpty) ...[
             const Padding(
               padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
               child: Text('⏳ 待ち時間のある展示ピックアップ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF529F))),
             ),
             _buildGroupList(waitTimeGroups, groups, activeTag),
          ],

          // Questionnaire Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Text('イベントアンケート', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                     if (isOrganizer)
                       IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF6B4EE6)), onPressed: _addSurveyDialog),
                  ]
                ),
                const SizedBox(height: 8),
                if (surveys.isEmpty)
                   const Text('現在アンケートはありません', style: TextStyle(color: Colors.grey))
                else
                   ...surveys.map((survey) {
                     return Card(
                       margin: const EdgeInsets.only(bottom: 8),
                       color: const Color(0xFF6B4EE6).withValues(alpha: 0.05),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: const Color(0xFF6B4EE6).withValues(alpha: 0.2))),
                       child: ListTile(
                         leading: const Icon(Icons.assessment, color: Color(0xFF6B4EE6)),
                         title: Text(survey.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                         trailing: const Icon(Icons.open_in_new),
                         onTap: () async {
                           final uri = Uri.parse(survey.url);
                           if (await canLaunchUrl(uri)) {
                             await launchUrl(uri);
                           }
                         },
                       ),
                     );
                   }),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
