class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String reportedItemId;
  final String reportedItemType; // 'product' or 'user'
  final String reportedUserId;
  final String reportedUserName;
  final String reason;
  final String description;
  final DateTime timestamp;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'

  Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.reportedItemId,
    required this.reportedItemType,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reason,
    required this.description,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reportedItemId': reportedItemId,
      'reportedItemType': reportedItemType,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reason': reason,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reporterEmail: map['reporterEmail'] ?? '',
      reportedItemId: map['reportedItemId'] ?? '',
      reportedItemType: map['reportedItemType'] ?? 'product',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedUserName: map['reportedUserName'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'pending',
    );
  }
}
