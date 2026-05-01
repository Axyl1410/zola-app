import 'package:zola/domain/models/auth_user.dart';

class AdminUsersPage {
  const AdminUsersPage({
    required this.users,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<AuthUser> users;
  final int total;
  final int limit;
  final int offset;

  static AdminUsersPage? fromJson(Map<String, dynamic> json) {
    final usersRaw = json['users'];
    final totalRaw = json['total'];
    final limitRaw = json['limit'];
    final offsetRaw = json['offset'];
    if (usersRaw is! List ||
        totalRaw is! int ||
        limitRaw is! int ||
        offsetRaw is! int) {
      return null;
    }

    final users = <AuthUser>[];
    for (final item in usersRaw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final user = AuthUser.fromJson(item);
      if (user != null) {
        users.add(user);
      }
    }

    return AdminUsersPage(
      users: users,
      total: totalRaw,
      limit: limitRaw,
      offset: offsetRaw,
    );
  }
}
