import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../core/api_client.dart';
import '../features/schedule/schedule_api.dart';
import '../features/schedule/schedule_repository.dart';

const Color _darkBg = Color(0xFF0f172a);
const Color _darkBg2 = Color(0xFF0b1224);
const Color _cardBg = Color(0xFF111a2e);
const Color _accent = Color(0xFF14b8a6);
const Color _border = Color(0xFF1f2b3f);
const Color _softText = Color(0xFF94a3b8);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ScheduleRepository repo;
  bool isLoading = true;
  String? error;
  DateTime focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final CalendarController _controller = CalendarController();
  List<Appointment> _appointments = <Appointment>[];
  String? _loadedMonthKey; // e.g. 2025-09

  @override
  void initState() {
    super.initState();
    repo = ScheduleRepository(api: ScheduleApi(ApiClient()));
    _controller.displayDate = focusedMonth;
    _loadEventsForMonth(focusedMonth);
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    if (_loadedMonthKey == key && _appointments.isNotEmpty) return;
    if (mounted) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    final start = DateTime(month.year, month.month, 1);
    final endExclusive = DateTime(month.year, month.month + 1, 1);
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      final events = await repo.getCalendarEvents(
        start: fmt(start),
        end: fmt(endExclusive),
      );
      final appts = <Appointment>[];
      for (final ev in events) {
        final startStr = ev['start']?.toString();
        final endStr = ev['end']?.toString();
        if (startStr == null || endStr == null) continue;
        final startD = DateTime.tryParse(startStr);
        final endD = DateTime.tryParse(endStr);
        if (startD == null || endD == null) continue;
        final title = ev['title']?.toString() ?? 'Route';
        final routeNo = ev['route_no']?.toString() ?? '';
        appts.add(
          Appointment(
            startTime: startD,
            endTime: endD,
            isAllDay: true,
            subject: title,
            notes: routeNo,
            color: const Color(0xFF059669),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _appointments = appts;
          _loadedMonthKey = key;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          _appointments = const [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openRouteDetails(String routeNo) async {
    try {
      final data = await repo.getCalendarRouteDetails(routeNo);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        backgroundColor: Colors.transparent,
        builder: (_) => _RouteDetailsSheet(data: data),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load route: $e')));
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMonthCell(BuildContext context, MonthCellDetails details) {
    final List<Object> appointments = details.appointments;
    final bool hasRoutes = appointments.isNotEmpty;
    final Appointment? firstRoute = hasRoutes
        ? appointments.first as Appointment
        : null;
    String? routeLabel;
    if (firstRoute != null) {
      final String subject = firstRoute.subject.toString().trim();
      if (subject.isNotEmpty) {
        routeLabel = subject;
      } else {
        final String notes = firstRoute.notes?.toString().trim() ?? '';
        if (notes.isNotEmpty) {
          routeLabel = notes;
        }
      }
    }

    final DateTime today = DateTime.now();
    final bool isToday = _isSameDate(details.date, today);
    final bool inCurrentMonth =
        details.date.month == focusedMonth.month &&
        details.date.year == focusedMonth.year;

    Color dayTextColor;
    if (isToday) {
      dayTextColor = Colors.white;
    } else if (inCurrentMonth) {
      dayTextColor = Colors.white70;
    } else {
      dayTextColor = _softText.withValues(alpha: 0.35);
    }

    final Color routeTextColor;
    if (isToday) {
      routeTextColor = Colors.white;
    } else if (inCurrentMonth) {
      routeTextColor = _accent;
    } else {
      routeTextColor = _accent.withValues(alpha: 0.4);
    }

    final BoxDecoration dayDecoration;
    if (isToday) {
      dayDecoration = BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(12),
        border: hasRoutes ? Border.all(color: Colors.white, width: 1.5) : null,
      );
    } else if (hasRoutes) {
      dayDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 1.5),
      );
    } else {
      dayDecoration = BoxDecoration(borderRadius: BorderRadius.circular(12));
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          decoration: dayDecoration,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${details.date.day}',
                style: TextStyle(
                  color: dayTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (routeLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    routeLabel,
                    style: TextStyle(
                      color: routeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
                          'Calendar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(
                              focusedMonth.year,
                              focusedMonth.month - 1,
                            );
                            _controller.displayDate = focusedMonth;
                          });
                          _loadEventsForMonth(focusedMonth);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.today, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                            );
                            _controller.displayDate = focusedMonth;
                          });
                          _loadEventsForMonth(focusedMonth);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(
                              focusedMonth.year,
                              focusedMonth.month + 1,
                            );
                            _controller.displayDate = focusedMonth;
                          });
                          _loadEventsForMonth(focusedMonth);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (error != null)
                      Container(
                        width: double.infinity,
                        color: Colors.amber.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Some calendar data could not be loaded. Showing month without events.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          SfCalendar(
                            view: CalendarView.month,
                            controller: _controller,
                            dataSource: _RouteDataSource(_appointments),
                            firstDayOfWeek: 7, // Sunday
                            todayHighlightColor: _accent,
                            todayTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            showDatePickerButton: false,
                            backgroundColor: Colors.transparent,
                            cellBorderColor: _border.withValues(alpha: 0.5),
                            headerHeight: 48,
                            viewHeaderHeight: 36,
                            headerStyle: const CalendarHeaderStyle(
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            viewHeaderStyle: const ViewHeaderStyle(
                              backgroundColor: Colors.transparent,
                              dayTextStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            monthViewSettings: MonthViewSettings(
                              appointmentDisplayMode:
                                  MonthAppointmentDisplayMode.none,
                              showAgenda: false,
                              monthCellStyle: const MonthCellStyle(
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                            monthCellBuilder: _buildMonthCell,
                            onViewChanged: (details) {
                              final visible = details.visibleDates;
                              if (visible.isNotEmpty) {
                                final mid = visible[visible.length ~/ 2];
                                final month = DateTime(mid.year, mid.month);
                                if (month.year != focusedMonth.year ||
                                    month.month != focusedMonth.month) {
                                  focusedMonth = month;
                                  _loadEventsForMonth(focusedMonth);
                                }
                              }
                            },
                            onTap: (details) {
                              final appointments = details.appointments;
                              if (appointments != null &&
                                  appointments.isNotEmpty) {
                                final app = appointments.first as Appointment;
                                final routeNo = app.notes;
                                if (routeNo is String && routeNo.isNotEmpty) {
                                  _openRouteDetails(routeNo);
                                }
                              }
                            },
                          ),
                          if (isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDataSource extends CalendarDataSource {
  _RouteDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class _RouteDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RouteDetailsSheet({required this.data});

  String _fmtDate(String? raw) {
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
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flights = List<Map<String, dynamic>>.from(
      data['Flights'] ?? const [],
    );
    final crew = List<Map<String, dynamic>>.from(
      data['CrewMembers'] ?? const [],
    );
    final statusText = (data['Status']?.toString() ?? '').toUpperCase().trim();
    final bool isCancelled =
        statusText.contains('CANCEL') || statusText.contains('REJECT');
    final bool isDelayed = statusText.contains('DELAY');
    final Color statusColor = isCancelled
        ? const Color(0xFFef4444)
        : isDelayed
        ? const Color(0xFFf97316)
        : _accent;
    final Color statusBg = statusColor.withValues(alpha: 0.18);
    final Color statusBorder = statusColor.withValues(alpha: 0.35);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darkBg, _darkBg2],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: _border)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(Icons.flight, color: _accent, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route ${data['RouteNumber'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmtDate(data['RouteDate']?.toString())} • AC: ${data['ACType'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: _softText,
                              fontSize: 13,
                            ),
                          ),
                          if (data['EndDate'] != null)
                            Text(
                              'Ends: ${_fmtDate(data['EndDate']?.toString())}',
                              style: const TextStyle(
                                color: _softText,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (statusText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Flights',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (flights.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Text(
                      'No flights scheduled for this route.',
                      style: TextStyle(color: _softText),
                    ),
                  )
                else
                  ...flights.map(
                    (f) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _fmtDate(f['FlightDate']?.toString()),
                                style: const TextStyle(
                                  color: _softText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${f['DepPort'] ?? 'N/A'} (${f['DepTime'] ?? 'N/A'}) → ${f['ArrPort'] ?? 'N/A'} (${f['ArrTime'] ?? 'N/A'})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _badge('AC ${f['ACType'] ?? 'N/A'}'),
                              _badge('RG ${f['ReportingGroup'] ?? 'N/A'}'),
                              _badge('Status ${f['Status'] ?? 'N/A'}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Crew Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (crew.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Text(
                      'No crew assignments available.',
                      style: TextStyle(color: _softText),
                    ),
                  )
                else
                  ...crew.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c['name'] ?? 'Unknown'} • ${c['p_no'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Duty: ${c['duty'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: _softText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _badge(c['position']?.toString() ?? 'N/A'),
                              _badge(c['category']?.toString() ?? 'N/A'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _accent.withValues(alpha: 0.25)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: _accent,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
