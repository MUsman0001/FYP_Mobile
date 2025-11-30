import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../features/leave/leave_api.dart';
import '../features/leave/leave_repository.dart';
import '../features/leave/models/leave_request.dart';
import 'create_leave_request_screen.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  List<LeaveRequest> leaveRequests = [];
  bool isLoading = true;
  String? error;
  late final LeaveRepository leaveRepository;
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    final api = LeaveApi(ApiClient());
    leaveRepository = LeaveRepository(api: api);
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await leaveRepository.getLeaveRequests(
        status: selectedFilter,
        perPage: 50,
      );

      setState(() {
        leaveRequests = response.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _refreshLeaveRequests() async {
    await _loadLeaveRequests();
  }

  Future<void> _deleteLeaveRequest(LeaveRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Leave Request'),
        content: Text(
          'Are you sure you want to remove your ${request.leaveType} leave request from ${DateFormat('MMM dd, yyyy').format(request.startDate)} to ${DateFormat('MMM dd, yyyy').format(request.endDate)}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await leaveRepository.deleteLeaveRequest(request.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request removed successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      _loadLeaveRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCreateRequest() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateLeaveRequestScreen()));

    if (result == true) {
      _loadLeaveRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Leave Requests'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLeaveRequests,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                selectedFilter = value == 'all' ? null : value;
              });
              _loadLeaveRequests();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateRequest,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            )
          : error != null
          ? _buildErrorWidget()
          : leaveRequests.isEmpty
          ? _buildEmptyWidget()
          : RefreshIndicator(
              onRefresh: _refreshLeaveRequests,
              color: AppTheme.primaryGreen,
              child: _buildLeaveRequestsList(),
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshLeaveRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Leave Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFilter != null
                  ? 'No $selectedFilter leave requests found.'
                  : 'You haven\'t submitted any leave requests yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateRequest,
              icon: const Icon(Icons.add),
              label: const Text('Submit Leave Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaveRequests.length,
      itemBuilder: (context, index) {
        final request = leaveRequests[index];
        return _buildLeaveRequestCard(request);
      },
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLeaveTypeIcon(request.leaveType),
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.leaveType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(request.status),
              ],
            ),

            const Divider(height: 24),

            // Date Range
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Days Count
            Row(
              children: [
                const Icon(Icons.timelapse, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${request.numberOfDays} day${request.numberOfDays > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),

            // Reason if provided
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.reason!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // HR Remarks if provided
            if (request.remarks != null && request.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HR: ${request.remarks}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Medical Document indicator
            if (request.medicalDocumentUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: AppTheme.secondaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Medical document attached',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryGreen,
                    ),
                  ),
                ],
              ),
            ],

            // Created Date
            const SizedBox(height: 8),
            Text(
              'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(request.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),

            // Remove Button for pending requests
            if (request.canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteLeaveRequest(request),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case LeaveStatus.pending:
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      case LeaveStatus.approved:
        backgroundColor = AppTheme.lightGreen;
        textColor = AppTheme.darkGreen;
        break;
      case LeaveStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case LeaveStatus.cancelled:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getLeaveTypeIcon(String leaveType) {
    final type = leaveType.toLowerCase();
    if (type.contains('sick')) return Icons.local_hospital;
    if (type.contains('emergency')) return Icons.warning_amber;
    if (type.contains('casual')) return Icons.weekend;
    return Icons.beach_access; // Annual leave
  }
}
