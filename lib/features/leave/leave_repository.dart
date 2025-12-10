import 'leave_api.dart';
import 'models/leave_request.dart';
import 'models/leave_type_rule.dart';

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
    required LeaveTypeRule rule,
    required DateTime startDate,
    required DateTime endDate,
    String? medicalDocumentPath,
  }) async {
    // Enforce min notice: start >= today + min_notice_days
    final today = DateTime.now();
    final earliest = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: rule.minNoticeDays));
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    if (startOnly.isBefore(earliest)) {
      throw Exception(
        'You must apply at least ${rule.minNoticeDays} day(s) in advance for ${rule.name}',
      );
    }

    // Validate end >= start
    if (endDate.isBefore(startDate)) {
      throw Exception('End date must be after or equal to start date');
    }

    // Calculate days and enforce max duration
    final daysOfLeave = endDate.difference(startDate).inDays + 1;
    if (daysOfLeave > rule.maxDurationDays) {
      throw Exception(
        'Maximum allowed duration for ${rule.name} is ${rule.maxDurationDays} days',
      );
    }

    // Enforce PDF requirement
    if (rule.pdfRequired &&
        (medicalDocumentPath == null || medicalDocumentPath.isEmpty)) {
      throw Exception('Medical document (PDF) is required for this leave type');
    }

    return await api.createLeaveRequest(
      leaveReason: rule.name,
      daysOfLeave: daysOfLeave,
      startDate: startDate,
      endDate: endDate,
      medicalDocumentPath: medicalDocumentPath,
    );
  }

  Future<List<LeaveTypeRule>> getLeaveTypes() async {
    return await api.getLeaveTypes();
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
