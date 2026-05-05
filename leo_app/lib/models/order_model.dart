class OrderModel {
  final String id;
  final String userId;
  final String method;
  final String address;
  final int total;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.method,
    required this.address,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      method: json['method'] as String? ?? '',
      address: json['address'] as String? ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method,
      'address': address,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
