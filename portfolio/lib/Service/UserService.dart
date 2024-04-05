import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';

class UserService {
  Dio dio = Dio(); // Используйте экземпляр Dio для запросов к API

  // Функция для обновления статуса заявки
  Future<bool> updateApplicationStatus(int applicationId, String newStatus, int userId, int projectId) async {
    try {
      final response = await dio.put(
        '$api/Applications/$applicationId',
        data: {
          'applicationId': applicationId,
          'userId': userId,
          'projectId': projectId,
          'status': newStatus,
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception when updating application status: $e');
      return false;
    }
  }

  // Функция для добавления пользователя в список участников проекта компании
  Future<bool> addCompanyProjectMember(int companyId, int userId, String role, String contributions) async {
    try {
      final response = await dio.post(
        '$api/CompanyProjectMembers',
        data: {
          'companyProjectID': companyId,
          'userID': userId,
          'role': role,
          'contributions': contributions,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Exception when adding company project member: $e');
      return false;
    }
  }
  Future<bool> deleteApplication(int applicationId) async {
    try {
      final response = await dio.delete('$api/Applications/$applicationId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Ошибка при вызове API для удаления заявки: $e');
      return false;
    }
  }

}
