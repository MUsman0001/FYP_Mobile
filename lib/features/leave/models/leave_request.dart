/// Leave request model matching the backend API response
class LeaveRequest {
  final int id;
  final String? pNo;
  final String leaveType;
  final int? days;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final LeaveStatus status;
  final String? remarks;
  final String? medicalDocumentUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? reviewedBy;
  final DateTime? reviewedAt;

  LeaveRequest({
    required this.id,
    this.pNo,
    required this.leaveType,
    this.days,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
    this.remarks,
    this.medicalDocumentUrl,
    required this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      pNo: json['p_no'] as String?,
      leaveType: json['leave_type'] ?? json['reason'] ?? '',
      days: json['days'] as int?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
      status: LeaveStatus.fromString(json['status'] as String? ?? 'pending'),
      remarks: json['remarks'] as String?,
      medicalDocumentUrl: json['medical_document_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as int?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  /// Calculate number of days between start and end date
  int get numberOfDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if the leave can be cancelled
  bool get canCancel => status == LeaveStatus.pending;

  /// Check if medical document is required (for Sick Leave)
  static bool requiresMedicalDocument(String leaveType) {
    return leaveType.toLowerCase().contains('sick');
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static LeaveStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return LeaveStatus.cancelled;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Leave types available for crew
enum LeaveType {
  sickLeave('Sick Leave', 'Sick'),
  casualLeave('Casual Leave', 'Casual'),
  annualLeave('Annual Leave', 'Annual'),
  emergencyLeave('Emergency Leave', 'Emergency');

  const LeaveType(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static LeaveType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sick':
      case 'sick leave':
        return LeaveType.sickLeave;
      case 'casual':
      case 'casual leave':
        return LeaveType.casualLeave;
      case 'annual':
      case 'annual leave':
        return LeaveType.annualLeave;
      case 'emergency':
      case 'emergency leave':
        return LeaveType.emergencyLeave;
      default:
        return LeaveType.annualLeave;
    }
  }

  bool get requiresMedicalDocument => this == LeaveType.sickLeave;
}

/// Pagination info from API response
class LeavePagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  LeavePagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory LeavePagination.fromJson(Map<String, dynamic> json) {
    return LeavePagination(
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 15,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// Response wrapper for paginated leave requests
class LeaveRequestsResponse {
  final List<LeaveRequest> items;
  final LeavePagination pagination;

  LeaveRequestsResponse({required this.items, required this.pagination});

  factory LeaveRequestsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<dynamic> itemsList;
    Map<String, dynamic>? paginationData;

    // Handle different response formats
    if (data is Map<String, dynamic>) {
      itemsList = data['items'] as List<dynamic>? ?? [];
      paginationData = data['pagination'] as Map<String, dynamic>?;
    } else if (data is List) {
      itemsList = data;
      paginationData = json['pagination'] as Map<String, dynamic>?;
    } else {
      itemsList = [];
      paginationData = json['pagination'] as Map<String, dynamic>?;
    }

    return LeaveRequestsResponse(
      items: itemsList
          .map((item) => LeaveRequest.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: paginationData != null
          ? LeavePagination.fromJson(paginationData)
          : LeavePagination(
              total: itemsList.length,
              perPage: 15,
              currentPage: 1,
              lastPage: 1,
            ),
    );
  }
}
