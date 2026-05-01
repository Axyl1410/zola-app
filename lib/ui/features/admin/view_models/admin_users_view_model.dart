import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/domain/models/auth_user.dart';

class AdminUsersState {
  const AdminUsersState({
    required this.users,
    this.query = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final List<AuthUser> users;
  final String query;
  final int page;
  final int pageSize;

  List<AuthUser> get filteredUsers {
    if (query.isEmpty) {
      return users;
    }
    final q = query.toLowerCase();
    return users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.role ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int get totalPages {
    final total = (filteredUsers.length / pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  int get currentPage {
    return page.clamp(1, totalPages);
  }

  List<AuthUser> get pageItems {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filteredUsers.length);
    return filteredUsers.sublist(start, end);
  }

  int get adminCount =>
      users.where((u) => (u.role ?? '').toLowerCase() == 'admin').length;
  int get bannedCount => users.where((u) => u.banned).length;

  AdminUsersState copyWith({
    List<AuthUser>? users,
    String? query,
    int? page,
    int? pageSize,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  static const List<AuthUser> _mockUsers = [
    AuthUser(
      id: 'u_001',
      name: 'Nguyễn Minh An',
      email: 'an@zola.app',
      emailVerified: true,
      updatedAt: '2026-05-02T00:18:00.000Z',
      role: 'admin',
      banned: false,
    ),
    AuthUser(
      id: 'u_002',
      name: 'Trần Gia Huy',
      email: 'huy@zola.app',
      emailVerified: true,
      updatedAt: '2026-05-01T23:58:00.000Z',
      role: 'user',
      banned: false,
    ),
    AuthUser(
      id: 'u_003',
      name: 'Lê Thu Hà',
      email: 'ha@zola.app',
      emailVerified: true,
      updatedAt: '2026-04-30T12:00:00.000Z',
      role: 'moderator',
      banned: true,
    ),
  ];

  @override
  AdminUsersState build() {
    return const AdminUsersState(users: _mockUsers);
  }

  void updateQuery(String value) {
    state = state.copyWith(query: value.trim(), page: 1);
  }

  void goToPreviousPage() {
    final nextPage = state.currentPage - 1;
    if (nextPage < 1) {
      return;
    }
    state = state.copyWith(page: nextPage);
  }

  void goToNextPage() {
    final nextPage = state.currentPage + 1;
    if (nextPage > state.totalPages) {
      return;
    }
    state = state.copyWith(page: nextPage);
  }
}

final adminUsersNotifierProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(
      AdminUsersNotifier.new,
    );
