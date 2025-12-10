import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../notification_api.dart';
import '../notification_repository.dart';
import '../notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _repo;
  final List<NotificationItem> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    final api = NotificationApi(client);
    _repo = NotificationRepository(api: api, storage: client.secureStorage);
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) {
      setState(() => _loading = true);
      _page = 1;
      _items.clear();
    }
    final page = await _repo.fetch(page: _page, perPage: 20);
    setState(() {
      _items.addAll(page.items);
      _lastPage = page.lastPage;
      _loading = false;
    });
    await NotificationsService.I.refreshUnreadCount();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    _page += 1;
    final page = await _repo.fetch(page: _page, perPage: 20);
    setState(() {
      _items.addAll(page.items);
      _loadingMore = false;
      _lastPage = page.lastPage;
    });
  }

  Future<void> _markAll() async {
    await _repo.markAllRead();
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        final it = _items[i];
        _items[i] = NotificationItem(
          id: it.id,
          title: it.title,
          body: it.body,
          read: true,
          createdAt: it.createdAt,
          type: it.type,
          data: it.data,
        );
      }
    });
    await NotificationsService.I.refreshUnreadCount();
  }

  Future<void> _markRead(NotificationItem item, int index) async {
    if (item.read) return;
    await _repo.markRead(item.id);
    setState(() {
      _items[index] = NotificationItem(
        id: item.id,
        title: item.title,
        body: item.body,
        read: true,
        createdAt: item.createdAt,
        type: item.type,
        data: item.data,
      );
    });
    await NotificationsService.I.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    // Match the darker theme style used on HomeScreen
    const Color darkBg = Color(0xFF0f172a);
    const Color cardBg = Color(0xFF111a2e);
    const Color border = Color(0xFF1f2b3f);
    const Color accent = Color(0xFF14b8a6);
    const Color softText = Color(0xFF94a3b8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _markAll,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkBg, Color(0xFF0b1224)],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _load(initial: true),
                color: accent,
                backgroundColor: darkBg,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: _items.length + (_page < _lastPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      _loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      );
                    }
                    final item = _items[index];
                    final expanded = _expanded.contains(item.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          setState(() {
                            if (expanded) {
                              _expanded.remove(item.id);
                            } else {
                              _expanded.add(item.id);
                            }
                          });
                          await _markRead(item, index);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item.read
                                          ? Icons.notifications_none
                                          : Icons.notifications,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (item.title.isEmpty
                                              ? _fallbackTitle(item)
                                              : item.title),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: item.read
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body.isEmpty
                                              ? _briefFromData(item.data)
                                              : item.body,
                                          style: const TextStyle(
                                            color: softText,
                                            fontSize: 13,
                                          ),
                                          maxLines: expanded ? 3 : 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: softText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        expanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (expanded) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: border),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: _detailBox(item, accent, softText),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // --- Helpers for richer details ---
  String _fallbackTitle(NotificationItem item) {
    final type = item.type.toLowerCase();
    if (type.contains('route') && type.contains('assign')) {
      return 'Route Assignment';
    }
    return 'Notification';
  }

  String _briefFromData(Map<String, dynamic> data) {
    final name = _extract(data, const [
      'name',
      'assignee_name',
      'user_name',
      'crew_name',
    ]);
    final route = _extract(data, const ['route', 'route_code', 'flight_route']);
    final date = _dateString(data);
    final parts = [
      if (name != null && name.isNotEmpty) name,
      if (route != null && route.isNotEmpty) route,
      if (date != null && date.isNotEmpty) date,
    ];
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  Widget _detailBox(NotificationItem item, Color accent, Color softText) {
    final data = item.data;
    // Prefer specific keys for route assignment
    final name = _extract(data, const [
      'name',
      'assignee_name',
      'user_name',
      'crew_name',
    ]);
    final route = _extract(data, const [
      'route',
      'route_code',
      'flight_route',
      'sector',
    ]);
    final date = _dateString(data);

    final rows = <Widget>[];
    if (name != null && name.isNotEmpty) {
      rows.add(_kv('Name', name, accent, softText));
    }
    if (route != null && route.isNotEmpty) {
      rows.add(_kv('Route', route, accent, softText));
    }
    if (date != null && date.isNotEmpty) {
      rows.add(_kv('Date', date, accent, softText));
    }

    // Fallback: show remaining key-values to be informative
    final shown = {
      'name',
      'assignee_name',
      'user_name',
      'crew_name',
      'route',
      'route_code',
      'flight_route',
      'sector',
      'date',
      'assignment_date',
      'assigned_date',
      'start_date',
    };
    final rest = data.entries
        .where((e) => !shown.contains(e.key))
        .take(6)
        .map(
          (e) => _kv(
            _labelize(e.key),
            e.value?.toString() ?? '',
            accent,
            softText,
          ),
        );
    rows.addAll(rest);

    if (rows.isEmpty) {
      rows.add(
        Text(
          item.body.isEmpty ? 'No additional details' : item.body,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _kv(String k, String v, Color accent, Color softText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(k, style: TextStyle(color: softText, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _extract(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null) return v.toString();
    }
    return null;
  }

  String? _dateString(Map<String, dynamic> data) {
    final raw = _extract(data, const [
      'date',
      'assignment_date',
      'assigned_date',
      'start_date',
    ]);
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw; // leave as-is
    return '${parsed.year}-${_two(parsed.month)}-${_two(parsed.day)}';
  }

  String _labelize(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
  }
}
