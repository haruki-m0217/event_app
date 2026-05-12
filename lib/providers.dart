import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Roles & General ---
enum UserRole { organizer, participant, superAdmin }

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.participant;
  void setRole(UserRole role) => state = role;
}
final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(() => UserRoleNotifier());

class IsGuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setGuest(bool value) => state = value;
}
final isGuestProvider = NotifierProvider<IsGuestNotifier, bool>(() => IsGuestNotifier());

// --- User Profile ---
class UserProfile {
  final String name;
  final String? avatarPath;
  UserProfile({required this.name, this.avatarPath});
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => UserProfile(name: 'テスト ユーザー', avatarPath: null);
  
  void updateProfile(String name, String? avatarPath) {
    state = UserProfile(name: name, avatarPath: avatarPath);
  }
}
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() => UserProfileNotifier());

// --- Event Member Roles ---
enum EventMemberRole { superAdmin, staff, exhibitionLead, participant }

class EventMember {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final EventMemberRole role;
  final String? assignedGroupId; // 展示代表の場合の担当グループID

  EventMember({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.assignedGroupId,
  });

  EventMember copyWith({
    EventMemberRole? role,
    String? assignedGroupId,
  }) {
    return EventMember(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role ?? this.role,
      assignedGroupId: assignedGroupId ?? this.assignedGroupId,
    );
  }

  factory EventMember.fromMap(Map<String, dynamic> data) {
    return EventMember(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: EventMemberRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => EventMemberRole.participant,
      ),
      assignedGroupId: data['assignedGroupId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'assignedGroupId': assignedGroupId,
  };
}

// メンバー一覧 Provider
class EventMembersNotifier extends Notifier<List<EventMember>> {
  @override
  List<EventMember> build() => [];

  void setCreator(String uid, String displayName, String? photoUrl) {
    // イベント作成者を最高管理者として登録
    if (!state.any((m) => m.uid == uid)) {
      state = [EventMember(uid: uid, displayName: displayName, photoUrl: photoUrl, role: EventMemberRole.superAdmin)];
    }
  }

  void addMember(String uid, String displayName, String? photoUrl) {
    if (!state.any((m) => m.uid == uid)) {
      state = [...state, EventMember(uid: uid, displayName: displayName, photoUrl: photoUrl, role: EventMemberRole.participant)];
    }
  }

  void updateRole(String uid, EventMemberRole newRole, {String? assignedGroupId}) {
    state = state.map((m) {
      if (m.uid == uid) return m.copyWith(role: newRole, assignedGroupId: assignedGroupId);
      return m;
    }).toList();
  }

  void removeRole(String uid) {
    state = state.map((m) {
      if (m.uid == uid) return m.copyWith(role: EventMemberRole.participant);
      return m;
    }).toList();
  }
}
final eventMembersProvider = NotifierProvider<EventMembersNotifier, List<EventMember>>(() => EventMembersNotifier());

// 現在ログイン中ユーザーのUID（Googleログイン後にセット）
class CurrentUserUidNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setUid(String uid) => state = uid;
}
final currentUserUidProvider = NotifierProvider<CurrentUserUidNotifier, String?>(() => CurrentUserUidNotifier());

// 現在ログイン中ユーザーのイベント内ロール
final currentEventRoleProvider = Provider<EventMemberRole>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return EventMemberRole.participant;
  final members = ref.watch(eventMembersProvider);
  final me = members.where((m) => m.uid == uid);
  if (me.isEmpty) return EventMemberRole.participant;
  return me.first.role;
});

// 表示用ロール名（最高管理者は自分だけに表示、他者には運営と見える）
String displayRoleName(EventMemberRole role, bool isSelf) {
  switch (role) {
    case EventMemberRole.superAdmin:
      return isSelf ? '最高管理者' : '運営';
    case EventMemberRole.staff:
      return '運営';
    case EventMemberRole.exhibitionLead:
      return '展示代表';
    case EventMemberRole.participant:
      return '参加者';
  }
}

// --- Audit Log ---
class AuditLogEntry {
  final String id;
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String action;
  final DateTime timestamp;

  AuditLogEntry({
    required this.id,
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.action,
    required this.timestamp,
  });

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> data) {
    return AuditLogEntry(
      id: id,
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      action: data['action'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'action': action,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class AuditLogNotifier extends Notifier<List<AuditLogEntry>> {
  @override
  List<AuditLogEntry> build() => [];

  void addEntry(AuditLogEntry entry) {
    state = [entry, ...state]; // 新しいものを先頭に
  }

  void logAction(String uid, String displayName, String? photoUrl, String action) {
    addEntry(AuditLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      action: action,
      timestamp: DateTime.now(),
    ));
  }
}
final auditLogProvider = NotifierProvider<AuditLogNotifier, List<AuditLogEntry>>(() => AuditLogNotifier());

// --- Event Status & Publish Data ---
class EventPublishNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void publish() => state = true;
}
final isEventPublishedProvider = NotifierProvider<EventPublishNotifier, bool>(() => EventPublishNotifier());

class EventCodeNotifier extends Notifier<String?> {
  // 開発用モック重複チェックリスト
  final _takenCodes = ['TEST-CODE', 'RESERVED', 'ADMIN']; 

  @override
  String? build() => null;

  void generateCode() {
    // 紛らわしい文字(0, O, 1, I)を除外した英数字(大文字のみ)を使用
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = math.Random();
    String newCode;
    do {
      newCode = List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
    } while (_takenCodes.contains(newCode));
    state = newCode;
  }

  bool trySetCustomCode(String code) {
    if (_takenCodes.contains(code)) {
      return false; // 重複あり
    }
    state = code;
    return true;
  }
}
final eventCodeProvider = NotifierProvider<EventCodeNotifier, String?>(() => EventCodeNotifier());

// --- Account Hub Mock Data ---
class CreatedEventsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['Gakusai 2026 (主催中)'];
}
final myCreatedEventsProvider = NotifierProvider<CreatedEventsNotifier, List<String>>(() => CreatedEventsNotifier());

class JoinedEventsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['オープンキャンパス 2026', '技術書典 2025'];

  void addEvent(String title) {
    if (!state.contains(title)) {
      state = [...state, title];
    }
  }
}
final myJoinedEventsProvider = NotifierProvider<JoinedEventsNotifier, List<String>>(() => JoinedEventsNotifier());

// --- Event Data Models ---
class EventItem {
  final String id;
  final String title;
  final DateTime date;
  final String time; // "14:30" format
  final String organizer;
  final String description;

  EventItem({
    required this.id,
    required this.title, 
    required this.date, 
    required this.time, 
    required this.organizer, 
    required this.description
  });

  DateTime get absoluteDateTime {
    final parts = time.split(':');
    final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  factory EventItem.fromMap(String id, Map<String, dynamic> data) {
    return EventItem(
      id: id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '00:00',
      organizer: data['organizer'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'time': time,
      'organizer': organizer,
      'description': description,
    };
  }
}

class PostItem {
  final String id;
  final String title;
  final String content;
  final String timeString;
  final String? imagePath;

  PostItem({required this.id, required this.title, required this.content, required this.timeString, this.imagePath});

  factory PostItem.fromMap(String id, Map<String, dynamic> data) {
    return PostItem(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timeString: data['timeString'] ?? '',
      imagePath: data['imagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'timeString': timeString,
      'imagePath': imagePath,
    };
  }
}

class GroupItem {
  final String id;
  final String name;
  final List<String> tags;
  final String? headerImagePath;
  final String description;
  final List<PostItem> posts;
  
  // Wait Time System
  final bool isWaitTimeSystemEnabled;
  final int capacityPerEntry; // n
  final int timePerEntryMinutes; // a
  final int distributedTickets; // s
  final List<EventItem> timelineEvents;

  GroupItem({
    required this.id,
    required this.name, 
    required this.tags, 
    this.headerImagePath, 
    this.description = '', 
    this.posts = const [],
    this.isWaitTimeSystemEnabled = false,
    this.capacityPerEntry = 10,
    this.timePerEntryMinutes = 5,
    this.distributedTickets = 0,
    this.timelineEvents = const [],
  });
  
  GroupItem copyWith({
    String? id,
    String? name, 
    List<String>? tags,
    String? headerImagePath,
    String? description,
    List<PostItem>? posts,
    bool? isWaitTimeSystemEnabled,
    int? capacityPerEntry,
    int? timePerEntryMinutes,
    int? distributedTickets,
    List<EventItem>? timelineEvents,
  }) {
    return GroupItem(
      id: id ?? this.id,
      name: name ?? this.name, 
      tags: tags ?? this.tags,
      headerImagePath: headerImagePath ?? this.headerImagePath,
      description: description ?? this.description,
      posts: posts ?? this.posts,
      isWaitTimeSystemEnabled: isWaitTimeSystemEnabled ?? this.isWaitTimeSystemEnabled,
      capacityPerEntry: capacityPerEntry ?? this.capacityPerEntry,
      timePerEntryMinutes: timePerEntryMinutes ?? this.timePerEntryMinutes,
      distributedTickets: distributedTickets ?? this.distributedTickets,
      timelineEvents: timelineEvents ?? this.timelineEvents,
    );
  }

  factory GroupItem.fromMap(String id, Map<String, dynamic> data) {
    var postsData = data['posts'] as List<dynamic>? ?? [];
    List<PostItem> loadedPosts = postsData.map((e) => PostItem.fromMap('', e as Map<String,dynamic>)).toList();

    return GroupItem(
      id: id,
      name: data['name'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      headerImagePath: data['headerImagePath'],
      description: data['description'] ?? '',
      posts: loadedPosts,
      isWaitTimeSystemEnabled: data['isWaitTimeSystemEnabled'] ?? false,
      capacityPerEntry: data['capacityPerEntry'] ?? 10,
      timePerEntryMinutes: data['timePerEntryMinutes'] ?? 5,
      distributedTickets: data['distributedTickets'] ?? 0,
      timelineEvents: (data['timelineEvents'] as List<dynamic>? ?? []).map((e) => EventItem.fromMap('', e as Map<String,dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
      'headerImagePath': headerImagePath,
      'description': description,
      'posts': posts.map((e) => e.toMap()).toList(),
      'isWaitTimeSystemEnabled': isWaitTimeSystemEnabled,
      'capacityPerEntry': capacityPerEntry,
      'timePerEntryMinutes': timePerEntryMinutes,
      'distributedTickets': distributedTickets,
      'timelineEvents': timelineEvents.map((e) => e.toMap()).toList(),
    };
  }
}

class SurveyItem {
  final String id;
  final String title;
  final String url;
  SurveyItem({required this.id, required this.title, required this.url});

  factory SurveyItem.fromMap(String id, Map<String, dynamic> data) {
    return SurveyItem(
      id: id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
    };
  }
}

// --- App State Providers ---

// 1. Event Name
class EventNameNotifier extends Notifier<String> {
  @override
  String build() => '新しいイベント';
  void setName(String name) => state = name;
}
final eventNameProvider = NotifierProvider<EventNameNotifier, String>(() => EventNameNotifier());

// 2. Timetable List
class TimetableNotifier extends Notifier<List<EventItem>> {
  @override
  List<EventItem> build() {
    final now = DateTime.now();
    return [
      EventItem(id: 'mock-1', title: '開会式', date: now, time: '10:00', organizer: '生徒会', description: 'グラウンドにて開会式を行います。'),
      EventItem(id: 'mock-2', title: 'ステージイベント', date: now, time: '11:00', organizer: '軽音部', description: '秋の特別ライブです。'),
    ];
  }

  void _sortChronologically() {
    final sorted = [...state];
    sorted.sort((a, b) => a.absoluteDateTime.compareTo(b.absoluteDateTime));
    state = sorted;
  }

  void addEvent(EventItem event) {
    state = [...state, event];
    _sortChronologically();
  }
  
  void insertEvent(int index, EventItem event) {
    final newList = [...state];
    newList.insert(index, event);
    state = newList;
    _sortChronologically();
  }
}
final timetableProvider = NotifierProvider<TimetableNotifier, List<EventItem>>(() => TimetableNotifier());

// 3. Groups List
class GroupsNotifier extends Notifier<List<GroupItem>> {
  @override
  List<GroupItem> build() => [
    GroupItem(
      id: 'group-1',
      name: '1年A組', 
      tags: ['展示', '1年'],
      description: 'お化け屋敷とタピオカドリンクの販売を行います。ぜひ来てください！',
      posts: [PostItem(id: 'post-1', title: '準備完了！', content: '教室の装飾が終わりました。', timeString: '10分前')],
      isWaitTimeSystemEnabled: true,
      capacityPerEntry: 10,
      timePerEntryMinutes: 5,
      distributedTickets: 30,
    ),
    GroupItem(
      id: 'group-2',
      name: '美術部', 
      tags: ['展示'],
      description: '部員たちの渾身の作品を展示しています。',
      posts: []
    ),
  ];

  void addGroup(String name) {
    final id = 'group-${DateTime.now().millisecondsSinceEpoch}';
    state = [...state, GroupItem(id: id, name: name, tags: ['展示'])];
  }

  void removeGroup(int index) {
    final newList = [...state];
    newList.removeAt(index);
    state = newList;
  }

  void addGroupTimelineEvent(int index, EventItem event) {
    final newList = [...state];
    final target = newList[index];
    final updatedTimeline = [...target.timelineEvents, event];
    // 日付順でソート
    updatedTimeline.sort((a, b) => a.absoluteDateTime.compareTo(b.absoluteDateTime));
    newList[index] = target.copyWith(timelineEvents: updatedTimeline);
    state = newList;
  }

  void addTagToGroup(int index, String tag) {
    final newList = [...state];
    final target = newList[index];
    if (!target.tags.contains(tag)) {
      newList[index] = target.copyWith(tags: [...target.tags, tag]);
      state = newList;
    }
  }

  void updateGroupTitle(int index, String newTitle) {
    final newList = [...state];
    newList[index] = newList[index].copyWith(name: newTitle);
    state = newList;
  }

  void updateGroupDescription(int index, String newDesc) {
    final newList = [...state];
    newList[index] = newList[index].copyWith(description: newDesc);
    state = newList;
  }

  void updateGroupHeaderImage(int index, String path) {
    final newList = [...state];
    newList[index] = newList[index].copyWith(headerImagePath: path);
    state = newList;
  }

  void addGroupPost(int index, PostItem post) {
    final newList = [...state];
    final target = newList[index];
    newList[index] = target.copyWith(posts: [post, ...target.posts]);
    state = newList;
  }

  void updateWaitTimeSettings(int index, {
    bool? isEnabled,
    int? capacity,
    int? timeMin,
    int? tickets,
  }) {
    final newList = [...state];
    final t = newList[index];
    newList[index] = t.copyWith(
      isWaitTimeSystemEnabled: isEnabled ?? t.isWaitTimeSystemEnabled,
      capacityPerEntry: capacity ?? t.capacityPerEntry,
      timePerEntryMinutes: timeMin ?? t.timePerEntryMinutes,
      distributedTickets: tickets ?? t.distributedTickets,
    );
    state = newList;
  }

  void incrementDistributedTickets(int index) {
    final newList = [...state];
    final t = newList[index];
    newList[index] = t.copyWith(distributedTickets: t.distributedTickets + 1);
    state = newList;
  }

  void decrementDistributedTickets(int index) {
    final newList = [...state];
    final t = newList[index];
    if (t.distributedTickets > 0) {
      newList[index] = t.copyWith(distributedTickets: t.distributedTickets - 1);
      state = newList;
    }
  }
}
final groupsProvider = NotifierProvider<GroupsNotifier, List<GroupItem>>(() => GroupsNotifier());

// 4. Campus Map State
class CampusMapState {
  final int totalFloors;
  final Map<String, String> floorImages;
  
  CampusMapState({this.totalFloors = 0, this.floorImages = const {}});
  
  CampusMapState copyWith({int? totalFloors, Map<String, String>? floorImages}) {
    return CampusMapState(
      totalFloors: totalFloors ?? this.totalFloors,
      floorImages: floorImages ?? this.floorImages,
    );
  }
}

class CampusMapNotifier extends Notifier<CampusMapState> {
  @override
  CampusMapState build() => CampusMapState();

  void setTotalFloors(int count) {
    state = state.copyWith(totalFloors: count);
  }

  void setImageForFloor(String floorTag, String path) {
    final newImages = Map<String, String>.from(state.floorImages);
    newImages[floorTag] = path;
    state = state.copyWith(floorImages: newImages);
  }
}
final campusMapProvider = NotifierProvider<CampusMapNotifier, CampusMapState>(() => CampusMapNotifier());

// 5. Active Reminders (Stores list of EventItems)
class ActiveRemindersNotifier extends Notifier<List<EventItem>> {
  @override
  List<EventItem> build() => [];
  
  void toggleReminder(EventItem item) {
    if (state.contains(item)) {
      state = state.where((e) => e != item).toList();
    } else {
      state = [...state, item];
    }
  }
}
final activeRemindersProvider = NotifierProvider<ActiveRemindersNotifier, List<EventItem>>(() => ActiveRemindersNotifier());

// 6. Surveys List
class SurveysNotifier extends Notifier<List<SurveyItem>> {
  @override
  List<SurveyItem> build() => [
    SurveyItem(id: 'survey-1', title: 'イベント全体アンケート', url: 'https://forms.google.com/dummy'),
  ];

  void addSurvey(SurveyItem item) {
    state = [...state, item];
  }
}
final surveysProvider = NotifierProvider<SurveysNotifier, List<SurveyItem>>(() => SurveysNotifier());

// 7. Active Filter Tag
class ActiveFilterTagNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setTag(String? tag) => state = tag;
}
final activeFilterTagProvider = NotifierProvider<ActiveFilterTagNotifier, String?>(() => ActiveFilterTagNotifier());

// --- Other dummy providers ---
class NotificationsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['新しいお知らせが届いています', '明日のイベント準備が開始しました'];

  void addNotification(String msg) {
    state = [msg, ...state];
  }
}
final notificationsProvider = NotifierProvider<NotificationsNotifier, List<String>>(() => NotificationsNotifier());

// --- Logged in Users Mock (for Super Admin) ---
class LoggedInUsersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [
    'admin_system@exhibition.local (最高管理者)',
    'organizer1@exhibition.local (主催者)',
    'user_abc@student.local',
    'user_xyz@student.local',
  ];
}
final loggedInUsersProvider = NotifierProvider<LoggedInUsersNotifier, List<String>>(() => LoggedInUsersNotifier());
