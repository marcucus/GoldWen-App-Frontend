class AdminUser {
  final String id;
  final String email;
  final String role;
  final DateTime? lastLogin;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    this.lastLogin,
    this.isActive = true,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
    };
  }
}