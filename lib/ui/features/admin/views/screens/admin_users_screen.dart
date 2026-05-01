import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/admin/view_models/admin_users_view_model.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCheckingSession = true;

  bool _isAdminUser(AuthUser? user) {
    return user?.role?.trim().toLowerCase() == 'admin';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardSession();
    });
  }

  Future<void> _guardSession() async {
    final authNotifier = ref.read(authStatusNotifierProvider.notifier);
    final outcome = await authNotifier.validateSessionForCriticalAction();
    if (!mounted) return;
    switch (outcome) {
      case SessionValidationOutcome.active:
        final user = await ref.read(currentUserProvider.future);
        if (!mounted) return;
        if (!_isAdminUser(user)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có quyền truy cập khu vực quản trị.'),
            ),
          );
          Navigator.of(context).maybePop();
          return;
        }
        break;
      case SessionValidationOutcome.banned:
        return;
      case SessionValidationOutcome.unauthenticated:
        await authNotifier.logout();
        return;
      case SessionValidationOutcome.transientFailure:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể xác thực phiên do mạng không ổn định. Vui lòng thử lại.',
            ),
          ),
        );
        Navigator.of(context).maybePop();
        return;
    }
    setState(() {
      _isCheckingSession = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = ref.watch(adminUsersNotifierProvider);
    final notifier = ref.read(adminUsersNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email, vai trò...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: notifier.updateQuery,
          ),
          const SizedBox(height: 12),
          ...state.pageItems.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AdminUserCard(
                user: user,
                onSetRole: () {},
                onToggleBan: () {},
                onSessions: () {},
                onImpersonate: () {},
                onResetPassword: () {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: state.currentPage > 1
                    ? notifier.goToPreviousPage
                    : null,
                child: const Text('Trang trước'),
              ),
              const Spacer(),
              Text('Trang ${state.currentPage} / ${state.totalPages}'),
              const Spacer(),
              OutlinedButton(
                onPressed: state.currentPage < state.totalPages
                    ? notifier.goToNextPage
                    : null,
                child: const Text('Trang sau'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.onSetRole,
    required this.onToggleBan,
    required this.onSessions,
    required this.onImpersonate,
    required this.onResetPassword,
  });

  final AuthUser user;
  final VoidCallback onSetRole;
  final VoidCallback onToggleBan;
  final VoidCallback onSessions;
  final VoidCallback onImpersonate;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, child: Icon(Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _RoleBadge(role: user.role ?? 'user'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                user.banned
                    ? Icons.block_outlined
                    : Icons.verified_user_outlined,
                size: 16,
                color: user.banned ? Colors.redAccent : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                user.banned ? 'Đang bị khóa' : 'Đang hoạt động',
                style: TextStyle(
                  color: user.banned ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Hoạt động: ${_formatLastActive(user.updatedAt)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onSetRole,
                child: const Text('Đổi role'),
              ),
              OutlinedButton(
                onPressed: onSessions,
                child: const Text('Phiên đăng nhập'),
              ),
              OutlinedButton(
                onPressed: onImpersonate,
                child: const Text('Mạo danh'),
              ),
              OutlinedButton(
                onPressed: onResetPassword,
                child: const Text('Đặt lại mật khẩu'),
              ),
              OutlinedButton(
                onPressed: onToggleBan,
                style: OutlinedButton.styleFrom(
                  backgroundColor: user.banned
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  foregroundColor: user.banned
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                  side: BorderSide(
                    color: user.banned
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                child: Text(user.banned ? 'Mở khóa' : 'Khóa tài khoản'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastActive(String? updatedAt) {
    if (updatedAt == null || updatedAt.isEmpty) {
      return 'Không rõ';
    }
    final parsed = DateTime.tryParse(updatedAt);
    if (parsed == null) {
      return updatedAt;
    }
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final normalized = role.toLowerCase();
    final color = switch (normalized) {
      'admin' => const Color(0xFFD32F2F),
      'moderator' => const Color(0xFFEF6C00),
      _ => const Color(0xFF1565C0),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
