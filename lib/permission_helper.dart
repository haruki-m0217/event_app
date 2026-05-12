import 'providers.dart';

/// イベント内権限チェックのヘルパークラス
class PermissionHelper {
  /// 全体の編集権限（最高管理者・運営）
  static bool canEditAll(EventMemberRole role) =>
      role == EventMemberRole.superAdmin || role == EventMemberRole.staff;

  /// 特定グループの編集権限
  /// - 運営・最高管理者: 全グループ編集可
  /// - 展示代表: 担当グループのみ
  static bool canEditGroup(
    EventMemberRole role,
    String groupId,
    String? assignedGroupId,
  ) {
    if (canEditAll(role)) return true;
    if (role == EventMemberRole.exhibitionLead) {
      return groupId == assignedGroupId;
    }
    return false;
  }

  /// タイムテーブルへの投稿権限（展示代表も特例でOK）
  static bool canPostTimetable(EventMemberRole role) =>
      role != EventMemberRole.participant;

  /// 他ユーザーへの権限付与権限（最高管理者・運営）
  static bool canManageRoles(EventMemberRole role) => canEditAll(role);

  /// 監査ログの閲覧権限（最高管理者・運営）
  static bool canViewAuditLog(EventMemberRole role) => canEditAll(role);

  /// ロール付与時に設定できるロールの選択肢
  /// 最高管理者は他の人を最高管理者にはできない（運営まで）
  static List<EventMemberRole> assignableRoles(EventMemberRole currentUserRole) {
    return [
      EventMemberRole.staff,
      EventMemberRole.exhibitionLead,
      EventMemberRole.participant,
    ];
  }
}
