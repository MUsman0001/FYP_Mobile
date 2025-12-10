import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../features/auth/auth_api.dart';
import '../features/auth/auth_repository.dart';
import '../features/notifications/notifications_service.dart';
import '../features/notifications/screens/notifications_screen.dart';
import 'login_screen.dart';
import 'schedule_screen.dart';
import 'calendar_screen.dart';
import 'leave_requests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  late final AuthRepository authRepository;

  // Palette kept near screen for reuse across sections
  static const Color _darkBg = Color(0xFF0f172a);
  static const Color _darkBg2 = Color(0xFF0b1224);
  static const Color _cardBg = Color(0xFF111a2e);
  static const Color _accent = Color(0xFF14b8a6);
  static const Color _border = Color(0xFF1f2b3f);
  static const Color _softText = Color(0xFF94a3b8);

  @override
  void initState() {
    super.initState();
    final api = AuthApi(ApiClient());
    authRepository = AuthRepository(
      api: api,
      storage: api.client.secureStorage,
    );
    _loadUser();
    // fetch unread notifications badge
    NotificationsService.I.refreshUnreadCount();
  }

  Future<void> _loadUser() async {
    try {
      final data = await authRepository.getCurrentUser();
      setState(() => user = data);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await authRepository.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _navigateToSchedules() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScheduleScreen()));
  }

  void _navigateToCalendar() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
  }

  void _navigateToLeaveRequests() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaveRequestsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final status = (user?['status'] ?? '').toString().toLowerCase();
    final isActive = status == 'active' || status == 'enabled';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_darkBg, _darkBg2],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      color: _softText,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['name'] ?? 'Crew Member',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notifications icon with badge
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  NotificationsService.I.unreadCount,
                              builder: (context, unread, _) {
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const NotificationsScreen(),
                                          ),
                                        );
                                        // Refresh count when returning
                                        NotificationsService.I
                                            .refreshUnreadCount();
                                      },
                                      icon: const Icon(
                                        Icons.notifications,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Notifications',
                                    ),
                                    if (unread > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            unread > 99 ? '99+' : '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Status card
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1dd1a1), Color(0xFF10b981)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.task_alt,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isActive
                                          ? 'Status: Active'
                                          : 'Status: ${status.isEmpty ? 'Unknown' : status}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Department: ${user?['department'] ?? '—'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _miniStat('P-Number', user?['p_no'] ?? '—'),
                                const SizedBox(width: 16),
                                _miniStat(
                                  'Department',
                                  user?['department'] ?? '—',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Quick Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _quickTile(
                              icon: Icons.schedule,
                              label: 'Schedules',
                              helper: 'View flights',
                              onTap: _navigateToSchedules,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _quickTile(
                              icon: Icons.calendar_month,
                              label: 'Calendar',
                              helper: 'View dates',
                              onTap: _navigateToCalendar,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _quickTile(
                              icon: Icons.event_available,
                              label: 'Leave',
                              helper: 'Request / view',
                              onTap: _navigateToLeaveRequests,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      const Text(
                        'Profile Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoRow(Icons.badge, 'Name', user?['name'] ?? '—'),
                            _infoRow(
                              Icons.business_center,
                              'Department',
                              user?['department'] ?? '—',
                            ),
                            _infoRow(
                              Icons.email_outlined,
                              'Email',
                              user?['email'] ?? '—',
                            ),
                            _infoRow(
                              Icons.numbers,
                              'P-Number',
                              user?['p_no'] ?? '—',
                            ),
                            _infoRow(
                              Icons.verified_user,
                              'Status',
                              isActive
                                  ? 'Active'
                                  : (status.isEmpty ? 'Unknown' : status),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String label,
    required String helper,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(helper, style: TextStyle(color: _softText, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _softText, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
