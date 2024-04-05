

class CompanyProject {
  final int companyProjectId;
  final int companyId;
  final int projectId;
  final String requirements;

  CompanyProject({
    required this.companyProjectId,
    required this.companyId,
    required this.projectId,
    required this.requirements,
  });

  factory CompanyProject.fromJson(Map<String, dynamic> json) {
    return CompanyProject(
      companyProjectId: json['companyProjectId'],
      companyId: json['companyId'],
      projectId: json['projectId'],
      requirements: json['requirements'],
    );
  }


}
