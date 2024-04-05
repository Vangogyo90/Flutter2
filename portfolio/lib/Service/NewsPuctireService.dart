import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';

class NewsPuctireService {
  Dio _dio = Dio();

  Future<Map<String, dynamic>> postNewsPuctire({

    required int pictureId,
    required int projectId,
  }) async {
    try {
      Response response = await _dio.post(
        '$api/ProjectPuctires',
        data: {
          'pictureId': pictureId,
          'projectId': projectId,
        },
      );

      return response.data;
    } catch (e) {
      print('Error posting newsPuctire: $e');
      throw e;
    }
  }
}
