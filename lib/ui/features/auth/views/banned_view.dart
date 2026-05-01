import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';

class BannedView extends ConsumerWidget {
  const BannedView({super.key});

  Future<void> _contactSupport(
    BuildContext context,
    AuthUser? user,
  ) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@zola.app',
      queryParameters: <String, String>{
        'subject': 'Khiếu nại tài khoản bị khóa',
        'body': 'Mã người dùng: ${user?.id ?? 'không xác định'}',
      },
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng email.')),
      );
    }
  }

  Future<void> _logout(WidgetRef ref) async {
    await ref.read(authStatusNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: userState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _BannedContent(
              user: null,
              onContactSupport: () => _contactSupport(context, null),
              onLogout: () => _logout(ref),
            ),
            data: (AuthUser? user) => _BannedContent(
              user: user,
              onContactSupport: () => _contactSupport(context, user),
              onLogout: () => _logout(ref),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannedContent extends StatelessWidget {
  const _BannedContent({
    required this.user,
    required this.onContactSupport,
    required this.onLogout,
  });

  final AuthUser? user;
  final VoidCallback onContactSupport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final reason = (user?.banReason != null && user!.banReason!.isNotEmpty)
        ? user!.banReason!
        : 'Vi phạm tiêu chuẩn cộng đồng.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.gpp_bad_outlined, size: 56, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text(
          'Tài khoản đã bị khóa',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          user?.email ?? 'Bạn không thể tiếp tục sử dụng ứng dụng lúc này.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _InfoTile(label: 'Lý do', value: reason),
        const SizedBox(height: 12),
        _InfoTile(
          label: 'Thời hạn',
          value: _formatBanExpiry(user?.banExpires),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onContactSupport,
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Liên hệ hỗ trợ / Khiếu nại'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ),
      ],
    );
  }

  String _formatBanExpiry(String? rawBanExpires) {
    if (rawBanExpires == null || rawBanExpires.isEmpty) {
      return 'Ban vĩnh viễn';
    }
    final parsed = DateTime.tryParse(rawBanExpires);
    if (parsed == null) {
      return rawBanExpires;
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
