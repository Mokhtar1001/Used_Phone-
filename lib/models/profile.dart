class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
