class UserModel {
  final String id;
  final String email;
  final String name;
  final String departmentId;
  final int level;
  final List<String> roles;
  final String? supervisorId;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.departmentId,
    required this.level,
    required this.roles,
    this.supervisorId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      departmentId: json['departmentId']?['_id'] ?? json['departmentId'] ?? '',
      level: json['level'] ?? 0,
      roles: List<String>.from(json['roles'] ?? []),
      supervisorId: json['supervisorId']?['_id'] ?? json['supervisorId'],
    );
  }

  bool get isSeniorStaff => level >= 14;
  bool hasRole(String role) => roles.contains(role);
}

