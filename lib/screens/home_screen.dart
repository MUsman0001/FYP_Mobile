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

  // Design System Color Palette
  static const Color _primaryBg = Color(0xFF0a1628);
  static const Color _accentStart = Color(0xFF00d4aa);
  static const Color _accentEnd = Color(0xFF00b896);
  static const Color _cardBgStart = Color(0xFF1a2942);
  static const Color _cardBgEnd = Color(0xFF152238);
  static const Color _border = Color(0xFF243650);
  static const Color _labelGray = Color(0xFF6b7280);

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
    return Scaffold(
      backgroundColor: _primaryBg,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentStart),
              ),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Section (Curved Turquoise Banner)
                  RepaintBoundary(child: _buildCurvedHeader()),

                  // 2. Employee ID Card (Floating with negative margin)
                  Transform.translate(
                    offset: const Offset(0, -42),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RepaintBoundary(child: _buildEmployeeIdCard()),
                    ),
                  ),

                  // Main content padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 0),

                        // 3. Quick Actions Grid
                        _buildQuickActionsSection(),

                        const SizedBox(height: 28),

                        // 4. Contact Information Section
                        _buildContactInfoSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 1. Curved Turquoise Banner Header
  Widget _buildCurvedHeader() {
    return Container(
      height: 285,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentStart, _accentEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Stack(
        children: [
          // Glassmorphism circular overlays
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: User icon + Welcome text | Bell + Logout
                  Row(
                    children: [
                      // User icon with glass effect
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?['name'] ?? 'Crew Member',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bell icon
                      ValueListenableBuilder<int>(
                        valueListenable: NotificationsService.I.unreadCount,
                        builder: (context, unread, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                    NotificationsService.I.refreshUnreadCount();
                                  },
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Logout icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: _logout,
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom Row: Three stat boxes
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          Icons.verified_user,
                          'Status',
                          (user?['status'] ?? '').toString().isEmpty
                              ? 'Unknown'
                              : (user?['status'] ?? '').toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                          Icons.business_center,
                          'Department',
                          user?['department'] ?? '—',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                          Icons.security,
                          'Role',
                          _getFirstRole(user?['roles']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. Employee ID Card (Floating)
  Widget _buildEmployeeIdCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBgStart, _cardBgEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Left side: Employee ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee ID',
                      style: TextStyle(
                        color: _labelGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?['p_no'] ?? 'P002',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Hash icon in turquoise circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accentStart, _accentEnd]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentStart.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tag, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentStart, _accentEnd],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.trending_up, color: _accentStart, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Quick Actions Grid
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: _accentStart, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        // First two buttons in a row
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.schedule,
                title: 'Schedules',
                description: 'View flight schedules',
                onTap: _navigateToSchedules,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                icon: Icons.calendar_month,
                title: 'Calendar',
                description: 'View your dates',
                onTap: _navigateToCalendar,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third button full width (horizontal layout)
        _quickActionCardHorizontal(
          icon: Icons.event_available,
          title: 'Request Leave',
          description: 'Submit or view leave requests',
          onTap: _navigateToLeaveRequests,
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardBgStart, _cardBgEnd],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accentStart, _accentEnd]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accentStart.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: _labelGray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCardHorizontal({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardBgStart, _cardBgEnd],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accentStart, _accentEnd]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accentStart.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: _labelGray, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: _accentStart, size: 20),
          ],
        ),
      ),
    );
  }

  // 4. Contact Information Section
  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Contact Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.mail_outline, color: _accentStart, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBgStart, _cardBgEnd],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _contactRow(Icons.email, 'Email Address', user?['email'] ?? '—'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: _border, thickness: 1, height: 1),
              ),
              _contactRow(
                Icons.people,
                'Role Assignment',
                _formatRoles(user?['roles']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_accentStart, _accentEnd]),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _labelGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRoles(dynamic roles) {
    if (roles == null) return '—';
    if (roles is List) {
      // Handle list of strings or list of maps
      final names = roles
          .map((e) {
            if (e is String) return e;
            if (e is Map && e.containsKey('role_name')) {
              return e['role_name']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
      return names.isEmpty ? '—' : names.join(', ');
    }
    // Fallback for unexpected types
    return roles.toString();
  }

  String _getFirstRole(dynamic roles) {
    if (roles == null) return '—';
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is String) return first;
      if (first is Map && first.containsKey('role_name')) {
        return first['role_name']?.toString() ?? '—';
      }
      return first.toString();
    }
    if (roles is String) return roles;
    return '—';
  }
}
