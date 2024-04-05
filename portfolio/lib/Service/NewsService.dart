import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';

class NewsService {
  Dio _dio = Dio();

  Future<Map<String, dynamic>> postNews({
    required String title,
    required String description,
    required String startDate, // Изменено на String
    required String endDate, // Изменено на String
    required String projectUrl,
    required int pictureId,
  }) async {
    try {
      Response response = await _dio.post(
        '$api/Projects',
        data: {
          'title': title,
          'description': description,
          'startDate': startDate, // Без изменений, т.к. уже строка
          'endDate': endDate, // Без изменений, т.к. уже строка
          'projectUrl': projectUrl,
          'pictureId': pictureId,
        },
      );

      return response.data;
    } catch (e) {
      print('Error posting news: $e');
      throw e;
    }
  }

  Future<void> editNews({
    required int newsId,
    required String newDescription,
  }) async {
    try {
      await _dio.put(
        '$api/Project/$newsId',
        queryParameters: {'newDescription': newDescription},
      );
    } catch (e) {
      print('Error editing news: $e');
      throw e;
    }
  }


  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final response = await _dio.get('$api/Projects');
      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load news data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news data: $e');
      throw Exception('Failed to load news data');
    }
  }

  Future<void> deleteNews(int newsId) async {
    try {
      // Удалить связанные записи из таблицы News_puctires
      await _dio.delete('$api/Project/pictures/$newsId');

      // Удалить связанные записи из таблицы Likes
      await _dio.delete('$api/Project/likes/$newsId');

      // Затем удалить саму новость
      await _dio.delete('$api/Project/$newsId');
    } catch (e) {
      print('Error deleting Project: $e');
      throw e;
    }
  }
}
