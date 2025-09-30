import 'schedule_api.dart';

class ScheduleRepository {
  final ScheduleApi api;

  ScheduleRepository({required this.api});

  Future<List<Map<String, dynamic>>> getMySchedule() async {
    try {
      final response = await api.getMySchedule();
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']['schedules']);
      } else {
        throw Exception('Failed to fetch schedule');
      }
    } catch (e) {
      throw Exception('Error fetching schedule: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getScheduleByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await api.getScheduleByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']['schedules']);
      } else {
        throw Exception('Failed to fetch schedule');
      }
    } catch (e) {
      throw Exception('Error fetching schedule: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCalendarEvents({
    String? start,
    String? end,
  }) async {
    try {
      final list = await api.getCalendarEvents(start: start, end: end);
      final result = <Map<String, dynamic>>[];
      for (final item in list) {
        if (item is Map) {
          // Coerce keys to String to be safe (handles Map<dynamic,dynamic>)
          final map = <String, dynamic>{};
          item.forEach((k, v) => map[k.toString()] = v);
          // Only accept well-formed calendar events
          if (map.containsKey('start') && map.containsKey('end')) {
            result.add(map);
          }
        }
      }
      return result;
    } catch (e) {
      // Be resilient: return empty list so calendar still renders
      return const [];
    }
  }

  Future<Map<String, dynamic>> getCalendarRouteDetails(String routeNo) async {
    try {
      final data = await api.getCalendarRouteDetails(routeNo);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('Error fetching route details: $e');
    }
  }
}
