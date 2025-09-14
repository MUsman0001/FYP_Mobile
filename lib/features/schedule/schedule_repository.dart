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
}
