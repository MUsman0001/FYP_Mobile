import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../features/schedule/schedule_api.dart';
import '../features/schedule/schedule_repository.dart';

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
        builder: (_) => _RouteDetailsSheet(data: data),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load route: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
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
            icon: const Icon(Icons.today),
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
            icon: const Icon(Icons.chevron_right),
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
      body: Column(
        children: [
          if (error != null)
            Container(
              width: double.infinity,
              color: Colors.amber[50],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some calendar data could not be loaded. Showing month without events.',
                      style: const TextStyle(fontSize: 12),
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
                  todayHighlightColor: AppTheme.primaryGreen,
                  showDatePickerButton: false,
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                    showAgenda: false,
                  ),
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
                    if ((details.appointments?.isNotEmpty ?? false)) {
                      final app = details.appointments!.first as Appointment;
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
                        AppTheme.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flight, color: Color(0xFF065F46)),
                    const SizedBox(width: 8),
                    Text(
                      'Route ${data['RouteNumber'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondaryGreen),
                      ),
                      child: Text(
                        (data['Status']?.toString() ?? '').toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.darkGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fmtDate(data['RouteDate']?.toString())} • AC: ${data['ACType'] ?? 'N/A'}',
                ),
                if (data['EndDate'] != null)
                  Text('Ends: ${_fmtDate(data['EndDate']?.toString())}'),
                const SizedBox(height: 16),

                const Text(
                  'Flights',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...flights.map(
                  (f) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
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
                              ),
                            ),
                            Text(
                              _fmtDate(f['FlightDate']?.toString()),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${f['DepPort'] ?? 'N/A'} (${f['DepTime'] ?? 'N/A'}) → ${f['ArrPort'] ?? 'N/A'} (${f['ArrTime'] ?? 'N/A'})',
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
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

                const SizedBox(height: 12),
                const Text(
                  'Crew Members',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...crew.map(
                  (c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c['name'] ?? 'Unknown'} • ${c['p_no'] ?? ''}',
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            _badge(c['position']?.toString() ?? 'N/A'),
                            _badge(c['category']?.toString() ?? 'N/A'),
                            _badge(c['duty']?.toString() ?? 'N/A'),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.secondaryGreen),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF065F46),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
