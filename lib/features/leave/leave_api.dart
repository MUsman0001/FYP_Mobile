import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import 'models/leave_request.dart';

class LeaveApi {
  final ApiClient client;

  LeaveApi(this.client);

  /// Get list of leave requests with optional filters
  /// GET /crew/leave-requests
  Future<LeaveRequestsResponse> getLeaveRequests({
    String? status,
    int perPage = 25,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{'per_page': perPage, 'page': page};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final Response response = await client.dio.get(
      '/crew/leave-requests',
      queryParameters: queryParams,
    );

    return LeaveRequestsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Get a single leave request by ID
  /// GET /crew/leave-requests/{id}
  Future<LeaveRequest> getLeaveRequest(int id) async {
    final Response response = await client.dio.get('/crew/leave-requests/$id');
    final data = response.data as Map<String, dynamic>;
    return LeaveRequest.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Create a new leave request
  /// POST /crew/leave-requests
  /// Uses multipart/form-data for file upload support
  Future<LeaveRequest> createLeaveRequest({
    required String leaveReason,
    required int daysOfLeave,
    required DateTime startDate,
    required DateTime endDate,
    String? medicalDocumentPath,
  }) async {
    final formMap = <String, dynamic>{
      'leave_reason': leaveReason,
      'days_of_leave': daysOfLeave.toString(),
      'leave_start_date': _formatDate(startDate),
      'leave_end_date': _formatDate(endDate),
    };

    if (medicalDocumentPath != null && medicalDocumentPath.isNotEmpty) {
      formMap['medical_document'] = await MultipartFile.fromFile(
        medicalDocumentPath,
        filename: 'medical_document.pdf',
      );
    }

    final formData = FormData.fromMap(formMap);

    final Response response = await client.dio.post(
      '/crew/leave-requests',
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return LeaveRequest.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Delete/remove a pending leave request
  /// DELETE /crew/leave-requests/{id}
  /// Note: This permanently deletes the request, not just cancels it
  Future<void> deleteLeaveRequest(int id) async {
    await client.dio.delete('/crew/leave-requests/$id');
  }

  /// Format DateTime to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
