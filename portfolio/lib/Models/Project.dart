class Project {
  final int projectId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String projectUrl;
  final int? pictureId;

  Project({
    required this.projectId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.projectUrl,
    this.pictureId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      projectUrl: json['projectUrl'],
      pictureId: json['pictureId'],
    );
  }
}
