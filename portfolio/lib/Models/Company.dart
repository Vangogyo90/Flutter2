class Company {
  final int companyId;
  final String companyName;
  final String contactInfo;
  final int userId;

  Company({
    required this.companyId,
    required this.companyName,
    required this.contactInfo,
    required this.userId,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyId: json['companyId'],
      companyName: json['companyName'],
      contactInfo: json['contactInfo'],
      userId: json['userId'],
    );
  }
}