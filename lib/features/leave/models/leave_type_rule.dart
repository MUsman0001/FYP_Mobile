/// Leave type rules model fetched from /api/leave-types
class LeaveTypeRule {
  final int id;
  final String name;
  final int minNoticeDays;
  final int maxDurationDays;
  final bool pdfRequired;

  LeaveTypeRule({
    required this.id,
    required this.name,
    required this.minNoticeDays,
    required this.maxDurationDays,
    required this.pdfRequired,
  });

  factory LeaveTypeRule.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, {int defaultValue = 0}) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
        // Handle boolean-like strings
        if (v.toLowerCase() == 'true') return 1;
        if (v.toLowerCase() == 'false') return 0;
        return defaultValue;
      }
      if (v is bool) return v ? 1 : 0;
      return defaultValue;
    }

    bool asBool(dynamic v, {bool defaultValue = false}) {
      if (v == null) return defaultValue;
      if (v is bool) return v;
      if (v is num) return v == 1;
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
        return defaultValue;
      }
      return defaultValue;
    }

    return LeaveTypeRule(
      id: asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      minNoticeDays: asInt(json['min_notice_days']),
      maxDurationDays: asInt(json['max_duration_days']),
      pdfRequired: asBool(json['pdf_required']),
    );
  }
}
