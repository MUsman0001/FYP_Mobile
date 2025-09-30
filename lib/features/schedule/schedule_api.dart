import '../../core/api_client.dart';

class ScheduleApi {
  final ApiClient client;

  ScheduleApi(this.client);

  Future<Map<String, dynamic>> getMySchedule() async {
    final response = await client.get('/crew/schedule');
    return response;
  }

  Future<Map<String, dynamic>> getScheduleByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final response = await client.get(
      '/crew/schedule/date-range',
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    return response;
  }

  // Calendar: returns top-level array of events
  Future<List<dynamic>> getCalendarEvents({String? start, String? end}) async {
    final response = await client.getList(
      '/crew/calendar/events',
      queryParameters: {
        if (start != null) 'start': start,
        if (end != null) 'end': end,
      },
    );
    return response;
  }

  // Calendar: route details for a specific route
  Future<Map<String, dynamic>> getCalendarRouteDetails(String routeNo) async {
    final response = await client.get('/crew/calendar/route/$routeNo');
    return response;
  }
}
