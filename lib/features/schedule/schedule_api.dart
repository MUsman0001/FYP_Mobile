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
}
