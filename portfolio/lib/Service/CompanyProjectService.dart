import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';
import '../Models/Project.dart';

class CompanyProjectService {
  final Dio _dio = Dio();

  Future<List<Project>> getCompanyProjects() async {
    try {
      final response = await _dio.get('$api/CompanyProjects');
      if (response.statusCode == 200) {
        List<Project> projects = (response.data as List)
            .map((projectJson) => Project.fromJson(projectJson))
            .toList();
        return projects;
      } else {
        throw Exception('Failed to load company projects');
      }
    } catch (e) {
      print('Error fetching company projects: $e');
      throw Exception('Failed to load company projects');
    }
  }
}
