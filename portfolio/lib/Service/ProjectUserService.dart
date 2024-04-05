import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';

class ProjectUserService {
  Dio _dio = Dio();

  Future<Map<String, dynamic>> postProjectUser({

    required int userId,
    required int projectId,
  }) async {
    try {
      Response response = await _dio.post(
        '$api/UserProjects',
        data: {
          'userId': userId,
          'projectId': projectId,
          'role': 'Администратор',
          'contributions': 'Разработка проекта',

        },
      );

      return response.data;
    } catch (e) {
      print('Error posting UserProjects: $e');
      throw e;
    }
  }
}
