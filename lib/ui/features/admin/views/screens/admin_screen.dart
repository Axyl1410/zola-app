import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';
import 'package:zola/ui/features/admin/view_models/admin_users_view_model.dart';
import 'package:zola/ui/routing/app_routes.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _isCheckingSession = true;

  bool _isAdminUser(AuthUser? user) {
    return user?.role?.trim().toLowerCase() == 'admin';
  }

  Future<bool> _ensureAdminAccess() async {
    final authNotifier = ref.read(authStatusNotifierProvider.notifier);
    final outcome = await authNotifier.validateSessionForCriticalAction();
    if (!mounted) {
      return false;
    }

    switch (outcome) {
      case SessionValidationOutcome.active:
        final user = await ref.read(currentUserProvider.future);
        if (!mounted) {
          return false;
        }
        if (!_isAdminUser(user)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có quyền truy cập khu vực quản trị.'),
            ),
          );
          context.go(AppRoute.homePersonal);
          return false;
        }
        return true;
      case SessionValidationOutcome.banned:
        return false;
      case SessionValidationOutcome.unauthenticated:
        await authNotifier.logout();
        return false;
      case SessionValidationOutcome.transientFailure:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể xác thực phiên do mạng không ổn định. Vui lòng thử lại.',
            ),
          ),
        );
        context.go(AppRoute.homePersonal);
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardSession();
    });
  }

  Future<void> _guardSession() async {
    final allowed = await _ensureAdminAccess();
    if (!mounted || !allowed) return;
    setState(() {
      _isCheckingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final usersState = ref.watch(adminUsersNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text(
          'Trang quản trị',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            context.go(AppRoute.homePersonal);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsRow(
            totalUsers: usersState.users.length,
            adminCount: usersState.adminCount,
            bannedCount: usersState.bannedCount,
          ),
          const SizedBox(height: 12),
          const _SectionTitle(
            title: 'Trung tâm quản trị',
            subtitle: 'Thao tác nhanh cho quản trị viên.',
          ),
          const SizedBox(height: 8),
          _QuickActionsCard(onCreateUser: () {}),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final allowed = await _ensureAdminAccess();
                if (!context.mounted || !allowed) {
                  return;
                }
                context.go(AppRoute.adminUsers);
              },
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text('Quản lý người dùng'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _NoteCard(),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    this.totalUsers = 0,
    this.adminCount = 0,
    this.bannedCount = 0,
  });

  final int totalUsers;
  final int adminCount;
  final int bannedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Tổng người dùng',
            value: totalUsers.toString(),
            icon: Icons.group_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Admin',
            value: adminCount.toString(),
            icon: Icons.admin_panel_settings_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Đang bị khóa',
            value: bannedCount.toString(),
            icon: Icons.block_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onCreateUser});

  final VoidCallback onCreateUser;

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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onCreateUser,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Tạo người dùng'),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Phân quyền'),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.supervised_user_circle_outlined),
            label: const Text('Mạo danh'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Lưu ý: Đây là giao diện quản trị mẫu. '
        'Danh sách người dùng được tách sang màn riêng để dễ mở rộng phân trang và lọc dữ liệu.',
        style: TextStyle(color: Color(0xFF6D4C41)),
      ),
    );
  }
}
