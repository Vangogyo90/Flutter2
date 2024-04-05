import 'package:dio/dio.dart';
import '../Api/ApiRequest.dart';

class CompanyProjectService {
  Dio _dio = Dio();

  Future<void> addCompanyProject({
    required int companyId,
    required int projectId,
    required String requirements,
  }) async {
    try {
      await _dio.post(
        '$api/CompanyProjects',
        data: {
          'companyId': companyId,
          'projectId': projectId,
          'requirements': requirements,
        },
      );
    } catch (e) {
      print('Error adding company project: $e');
      throw e;
    }
  }
}
