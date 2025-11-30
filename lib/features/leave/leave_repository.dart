import 'leave_api.dart';
import 'models/leave_request.dart';

class LeaveRepository {
  final LeaveApi api;

  LeaveRepository({required this.api});

  /// Get all leave requests with optional filtering
  Future<LeaveRequestsResponse> getLeaveRequests({
    String? status,
    int perPage = 25,
    int page = 1,
  }) async {
    return await api.getLeaveRequests(
      status: status,
      perPage: perPage,
      page: page,
    );
  }

  /// Get a single leave request details
  Future<LeaveRequest> getLeaveRequest(int id) async {
    return await api.getLeaveRequest(id);
  }

  /// Submit a new leave request
  Future<LeaveRequest> submitLeaveRequest({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? medicalDocumentPath,
  }) async {
    // Validate that sick leave has medical document
    if (leaveType.requiresMedicalDocument &&
        (medicalDocumentPath == null || medicalDocumentPath.isEmpty)) {
      throw Exception(
        'Medical document is required for ${leaveType.displayName}',
      );
    }

    // Validate dates
    if (endDate.isBefore(startDate)) {
      throw Exception('End date must be after or equal to start date');
    }

    // Validate start date is not in the past
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDateOnly = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (startDateOnly.isBefore(todayDate)) {
      throw Exception('Start date cannot be in the past');
    }

    // Calculate days of leave
    final daysOfLeave = endDate.difference(startDate).inDays + 1;

    return await api.createLeaveRequest(
      leaveReason: leaveType.displayName,
      daysOfLeave: daysOfLeave,
      startDate: startDate,
      endDate: endDate,
      medicalDocumentPath: medicalDocumentPath,
    );
  }

  /// Delete/remove a pending leave request (permanently removes it)
  Future<void> deleteLeaveRequest(int id) async {
    await api.deleteLeaveRequest(id);
  }

  /// Get only pending leave requests
  Future<LeaveRequestsResponse> getPendingRequests({int perPage = 25}) async {
    return await getLeaveRequests(status: 'pending', perPage: perPage);
  }

  /// Get leave request history (approved/rejected)
  Future<LeaveRequestsResponse> getLeaveHistory({int perPage = 25}) async {
    // Fetch all and filter client-side, or make separate calls
    return await getLeaveRequests(perPage: perPage);
  }
}
