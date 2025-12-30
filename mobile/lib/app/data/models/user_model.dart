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
    // Handle level conversion - can be int or String
    int levelValue = 0;
    if (json['level'] != null) {
      if (json['level'] is int) {
        levelValue = json['level'] as int;
      } else if (json['level'] is String) {
        levelValue = int.tryParse(json['level'] as String) ?? 0;
      } else if (json['level'] is num) {
        levelValue = (json['level'] as num).toInt();
      }
    }

    // Handle departmentId - can be string or object
    String departmentIdValue = '';
    if (json['departmentId'] != null) {
      if (json['departmentId'] is Map) {
        departmentIdValue = json['departmentId']?['_id']?.toString() ?? 
                           json['departmentId']?['id']?.toString() ?? '';
      } else {
        departmentIdValue = json['departmentId'].toString();
      }
    }

    // Handle roles - ensure it's a List<String>
    List<String> rolesList = [];
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        rolesList = (json['roles'] as List).map((e) => e.toString()).toList();
      }
    }

    // Handle supervisorId - can be null, string, or object
    String? supervisorIdValue;
    if (json['supervisorId'] != null) {
      if (json['supervisorId'] is Map) {
        supervisorIdValue = json['supervisorId']?['_id']?.toString() ?? 
                           json['supervisorId']?['id']?.toString();
      } else {
        supervisorIdValue = json['supervisorId'].toString();
      }
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      departmentId: departmentIdValue,
      level: levelValue,
      roles: rolesList,
      supervisorId: supervisorIdValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'departmentId': departmentId,
      'level': level,
      'roles': roles,
      'supervisorId': supervisorId,
    };
  }

  bool get isSeniorStaff => level >= 14;
  bool hasRole(String role) => roles.contains(role);
}

