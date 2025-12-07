import 'package:flutter/material.dart';
import '../features/schedule/schedule_repository.dart';
import '../features/schedule/schedule_api.dart';
import '../core/api_client.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  String? error;
  late final ScheduleRepository scheduleRepository;
  final Set<int> _expanded = <int>{};
  final Map<int, String> _activeTab = <int, String>{}; // 'flights' or 'crew'

  // Palette for consistency with auth/home screens
  static const Color _darkBg = Color(0xFF0f172a);
  static const Color _darkBg2 = Color(0xFF0b1224);
  static const Color _cardBg = Color(0xFF111a2e);
  static const Color _accent = Color(0xFF14b8a6);
  static const Color _border = Color(0xFF1f2b3f);
  static const Color _softText = Color(0xFF94a3b8);

  bool _isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;

  @override
  void initState() {
    super.initState();
    final api = ScheduleApi(ApiClient());
    scheduleRepository = ScheduleRepository(api: api);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final data = await scheduleRepository.getMySchedule();
      setState(() {
        schedules = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshSchedules() async {
    await _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'My Flight Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: _refreshSchedules,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_accent),
                        ),
                      )
                    : error != null
                    ? _buildErrorWidget()
                    : schedules.isEmpty
                    ? _buildEmptyWidget()
                    : _buildScheduleList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _darkBg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_outlined, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No Schedule Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any scheduled duties at the moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _darkBg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return RefreshIndicator(
      onRefresh: _refreshSchedules,
      color: _accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return _buildRouteCard(schedule, index);
        },
      ),
    );
  }

  // New card matching web view grouping
  Widget _buildRouteCard(Map<String, dynamic> route, int index) {
    final routeNumber = route['RouteNumber']?.toString() ?? 'N/A';
    final routeDate = _formatDate(route['RouteDate']?.toString());
    final acType = route['ACType']?.toString() ?? 'N/A';
    final status = route['Status']?.toString() ?? 'N/A';
    final flightCount = route['FlightCount'] is int
        ? route['FlightCount'] as int
        : int.tryParse(route['FlightCount']?.toString() ?? '') ?? 0;
    final crewCount = route['CrewCount'] is int
        ? route['CrewCount'] as int
        : int.tryParse(route['CrewCount']?.toString() ?? '') ?? 0;

    final isExpanded = _expanded.contains(index);
    final activeTab = _activeTab[index] ?? 'flights';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Header (tap to expand)
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(index);
              } else {
                _expanded.add(index);
                _activeTab[index] = 'flights';
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      runSpacing: 10,
                      spacing: 20,
                      children: [
                        _headerDetail('Route Number', routeNumber),
                        _headerDetail('Route Date', routeDate),
                        _headerDetail('Aircraft Type', acType),
                        _headerDetail(
                          'Flights',
                          '$flightCount ${flightCount == 1 ? 'flight' : 'flights'}',
                        ),
                        _headerDetail(
                          'Crew Members',
                          '$crewCount ${crewCount == 1 ? 'member' : 'members'}',
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0,
                    child: Icon(Icons.expand_more, color: _accent),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  _tabButton(
                    index: index,
                    tab: 'flights',
                    label: 'Flights',
                    active: activeTab == 'flights',
                  ),
                  _tabButton(
                    index: index,
                    tab: 'crew',
                    label: 'Crew Members',
                    active: activeTab == 'crew',
                  ),
                ],
              ),
            ),

            if (activeTab == 'flights') _flightsTab(context, route),
            if (activeTab == 'crew') _crewTab(route),
          ],
        ],
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required String tab,
    required String label,
    required bool active,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _activeTab[index] = tab),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: active
              ? _accent.withValues(alpha: 0.15)
              : Colors.transparent,
          foregroundColor: active ? _accent : Colors.grey[300],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _crewTab(Map<String, dynamic> route) {
    final crew = List<Map<String, dynamic>>.from(
      route['CrewMembers'] ?? const [],
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: crew.map((cm) => _crewRow(cm)).toList()),
    );
  }

  // Flights tab with responsive layout
  Widget _flightsTab(BuildContext context, Map<String, dynamic> route) {
    final flights = List<Map<String, dynamic>>.from(
      route['Flights'] ?? const [],
    );
    final compact = _isCompact(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            _tableHeader([
              'Flight No',
              'Date',
              'Departure',
              'Arrival',
              'Aircraft',
              'Status',
              'Reporting',
            ]),
          if (!compact) const SizedBox(height: 8),
          ...flights.map((f) => _flightRow(f, compact: compact)),
        ],
      ),
    );
  }

  Widget _flightRow(Map<String, dynamic> f, {required bool compact}) {
    final date = _formatDate(f['FlightDate']?.toString());
    final dep = f['DepPort']?.toString() ?? 'N/A';
    final arr = f['ArrPort']?.toString() ?? 'N/A';
    final depTime = f['DepTime']?.toString() ?? 'N/A';
    final arrTime = f['ArrTime']?.toString() ?? 'N/A';
    final acType = f['ACType']?.toString() ?? 'N/A';
    final status = f['Status']?.toString() ?? 'N/A';
    final rg = f['ReportingGroup']?.toString() ?? 'N/A';

    if (compact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  f['FlightNo']?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(date, style: TextStyle(color: _softText, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.flight_takeoff,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$dep ($depTime) → $arr ($arrTime)',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(
                  text: acType,
                  bg: _accent.withValues(alpha: 0.15),
                  fg: _accent,
                ),
                _buildStatusChip(status),
                Text(
                  'RG: $rg',
                  style: TextStyle(color: _softText, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cell(f['FlightNo']?.toString() ?? 'N/A', flex: 2, bold: true),
          _cell(date, flex: 3),
          _cell('$dep\n$depTime', flex: 3),
          _cell('$arr\n$arrTime', flex: 3),
          _cell(acType, flex: 2),
          Expanded(flex: 2, child: _buildStatusChip(status)),
          _cell(rg, flex: 3),
        ],
      ),
    );
  }

  Widget _crewRow(Map<String, dynamic> cm) {
    final name = cm['name']?.toString() ?? 'Unknown';
    final pno = cm['p_no']?.toString() ?? 'N/A';
    final position = cm['position']?.toString() ?? 'N/A';
    final category = cm['category']?.toString() ?? 'N/A';
    final duty = cm['duty']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'P-No: $pno',
                  style: TextStyle(color: _softText, fontSize: 12),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _chip(
                text: position,
                bg: _accent.withValues(alpha: 0.15),
                fg: _accent,
              ),
              _chip(
                text: category,
                bg: Colors.white.withValues(alpha: 0.06),
                fg: Colors.white,
              ),
              _chip(
                text: duty,
                bg: Colors.orange.withValues(alpha: 0.12),
                fg: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required String text, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: cols
            .map(
              (c) => Expanded(
                flex: c == 'Reporting' ? 3 : 2,
                child: Text(
                  c,
                  style: TextStyle(
                    color: _softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _cell(String text, {int flex = 2, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _headerDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _softText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color backgroundColor;
    Color textColor;

    switch (status?.toLowerCase()) {
      case 'published':
      case 'active':
        backgroundColor = _accent.withValues(alpha: 0.15);
        textColor = _accent;
        break;
      case 'completed':
      case 'cancelled':
        backgroundColor = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.redAccent;
        break;
      default:
        backgroundColor = Colors.white.withValues(alpha: 0.08);
        textColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Simple date formatter avoiding intl dependency
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final m = months[dt.month - 1];
      final d = dt.day.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$m $d, $y';
    } catch (_) {
      return raw;
    }
  }
}
