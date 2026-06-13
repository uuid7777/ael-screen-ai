class SubscriptionModel {
  final String id;
  final String userId;
  final String planType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String paymentProvider;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    this.paymentProvider = 'apple',
  });

  bool get isActive =>
      status == 'active' && endDate.isAfter(DateTime.now());

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planType: json['plan_type'] as String? ?? 'monthly',
      status: json['status'] as String? ?? 'active',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      autoRenew: json['auto_renew'] as bool? ?? true,
      paymentProvider: json['payment_provider'] as String? ?? 'apple',
    );
  }
}
