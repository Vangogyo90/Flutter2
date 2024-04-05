import '../Api/ApiRequest.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String? password;
  final String? skills;
  final String? education;
  final String? achievements;
  // Другие поля, конструктор и методы, если необходимо.

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
     this.middleName,
    required this.email,
    this.password,
    this.skills,
    this.education,
    this.achievements,
  });

  // Добавьте конструктор fromJson для разбора данных JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? IDUser, // Если 'idUser' равно null, используем значение по умолчанию (например, 0).
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      skills: json['skills'],
      education: json['education'],
      achievements: json['achievements'],
      // И другие поля, если необходимо.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'password': password,
      'skills': skills,
      'education': education,
      'achievements': achievements
    };
  }

  String get fullName => "$firstName ${middleName ?? ''} $lastName".trim();

}
