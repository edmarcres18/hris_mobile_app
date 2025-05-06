class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? suffix;
  final String email;
  final String? profileImage;
  final String? bio;
  final bool isOnline;
  final List<String> roles;
  final dynamic employee;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
    required this.email,
    this.profileImage,
    this.bio,
    required this.isOnline,
    required this.roles,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      middleName: json['middle_name'] as String?,
      suffix: json['suffix'] as String?,
      email: json['email'] as String,
      profileImage: json['profile_image'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['is_online'] == true || json['is_online'] == 'Online',
      roles: List<String>.from(json['roles'] ?? []),
      employee: json['employee'],
    );
  }
  
  // Get user initials for avatar
  String get initials {
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0];
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0];
    }
    return initials.toUpperCase();
  }
  
  // Get full name
  String get fullName => '$firstName $lastName';
  
  // Check if user has a specific role
  bool hasRole(String role) {
    return roles.contains(role);
  }
  
  // Check if user is an employee
  bool get isEmployee => hasRole('Employee');
  
  // Check if user is a supervisor
  bool get isSupervisor => hasRole('Supervisor');
  
  // Get user position (from employee data)
  String? get position {
    if (employee != null && employee['position'] != null) {
      return employee['position'];
    }
    return null;
  }
  
  // Get user department (from employee data)
  String? get department {
    if (employee != null && employee['department'] != null) {
      return employee['department'];
    }
    return null;
  }
} 