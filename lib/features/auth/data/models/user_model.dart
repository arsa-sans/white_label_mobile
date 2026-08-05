class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String tenantId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'visitor',
      tenantId: json['tenant_id'] ?? 'tenant-001',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'tenant_id': tenantId,
      };
}
