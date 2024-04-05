class Application {
  final int? applicationId;
  final int userId;
  final int projectId;
  final String status;

  Application({
    this.applicationId,
    required this.userId,
    required this.projectId,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'projectId': projectId,
    'status': status,
  };

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId: json['applicationId'] as int,
      userId: json['userId'] as int,
      projectId: json['projectId'] as int,
      status: json['status'] as String,
    );
  }


}
