class VehicleDocument {
  final String id;
  final String userId;
  final String type;
  final String label;
  final String documentNumber;
  final String vehiclePlate;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final String photoUrl;

  VehicleDocument({
    required this.id,
    required this.userId,
    required this.type,
    required this.label,
    required this.documentNumber,
    required this.vehiclePlate,
    this.issueDate,
    required this.expiryDate,
    required this.photoUrl,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      documentNumber: json['documentNumber']?.toString() ?? '',
      vehiclePlate: json['vehiclePlate']?.toString() ?? '',
      issueDate:
          json['issueDate'] != null ? DateTime.parse(json['issueDate']) : null,
      expiryDate: DateTime.parse(json['expiryDate']),
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;

  String get formattedExpiry =>
      '${expiryDate.year}.${expiryDate.month.toString().padLeft(2, '0')}.${expiryDate.day.toString().padLeft(2, '0')}';
}
