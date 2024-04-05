class UserWithRole {
  final int userId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String role;
  final String contributions;

  UserWithRole({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.role,
    required this.contributions,
  });

  factory UserWithRole.fromJson(Map<String, dynamic> json) {
    return UserWithRole(
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      middleName: json['middleName'],
      role: json['role'],
      contributions: json['contributions'],
    );
  }
}
