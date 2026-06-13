class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isPremium;
  final DateTime? subscriptionExpires;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.isPremium = false,
    this.subscriptionExpires,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionExpires: json['subscription_expires'] != null
          ? DateTime.parse(json['subscription_expires'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'created_at': createdAt?.toIso8601String(),
        'is_premium': isPremium,
        'subscription_expires': subscriptionExpires?.toIso8601String(),
      };
}
