
import 'package:dio/dio.dart';
import 'package:portfolio/Models/Course.dart';

import '../Models/Company.dart';
import '../Models/Group.dart';

final dio = Dio();
final http = HttpClientAdapter();
String api = 'http://192.168.1.68:5025/api';
var IDUser = '';




Future<dynamic> getID(String login) async{
  Response response;
  response = await dio.get('$api/Users/GetUserIdByLogin?loginUser=$login');
  print(response.data.toString());
  IDUser = response.data.toString();

}

/*String login="";
String password="";*/

Future<dynamic> request(String login, String password) async {
/*  login = _loginController.text;
  password = _passwordController.text;*/

  try {
    Response response = await dio.get('$api/Users/$login/$password');
    print(response.data.toString());
    // Handle the response here
  } catch (e) {
    if (e is DioError) {
      print("Dio Error: ${e.message}");
      print("Dio Response: ${e.response?.data}");
    }
  }
}

void registration(String firstName, String lastName, String middleName, String email, String password, int groupId, int courseId) async {
  Response response;
  try {
    response = await dio.post('$api/Users', data: {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'password': password,
      'groupsId': groupId,
      'courseId': courseId,
      'roleId': 2, // предполагаем, что roleId уже определен для вашего случая
      'salt': '' // Поскольку соль генерируется на сервере, здесь оставляем пустым
    });
    print("Регистрация успешна: ${response.data}");
  } catch (e) {
    print("Ошибка при регистрации: $e");
    if (e is DioError) {
      // Обработка ошибки Dio, если таковая произойдет
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    }
  }
}


void registrationWEB(String firstName, String lastName, String middleName, String email, String password) async {
  Response response;
  try {
    response = await dio.post('$api/Users', data: {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'password': password,
      'roleId': 3, // предполагаем, что roleId уже определен для вашего случая
      'salt': '' // Поскольку соль генерируется на сервере, здесь оставляем пустым
    });
    print("Регистрация успешна: ${response.data}");
  } catch (e) {
    print("Ошибка при регистрации: $e");
    if (e is DioError) {
      // Обработка ошибки Dio, если таковая произойдет
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    }
  }
}


Future<List<Group>> getGroups() async {
  Response response = await dio.get('$api/Groups');
  if (response.statusCode == 200) {
    List<dynamic> groupData = response.data;
    List<Group> groups = groupData.map((data) {
      return Group(id: data['groupsId'], name: data['groupName']);
    }).toList();
    return groups;
  } else {
    throw Exception('Failed to load groups');
  }
}

Future<List<Course>> getCourses() async {
  Response response = await dio.get('$api/Courses');
  if (response.statusCode == 200) {
    List<dynamic> courseData = response.data;
    List<Course> courses = courseData.map((data) {
      return Course(id: data['courseId'], number: data['number']);
    }).toList();
    return courses;
  } else {
    throw Exception('Failed to load courses');
  }
}

Future<Company?> createCompany(String name, String contactInfo) async {
  try {
    final response = await Dio().post(
      '$api/Companies', // Замените на фактический URL API
      data: {
        'companyName': name,
        'contactInfo': contactInfo,
         'userId': IDUser, // Вы должны также передать ID пользователя, если это необходимо
      },
    );

    if (response.statusCode == 201) {
      return Company.fromJson(response.data);
    }
  } catch (e) {
    print(e);
    return null;
  }
}




class NewsPuctireData {
  final Map<String, dynamic> pictureData;
  final Map<String, dynamic> newsData;

  NewsPuctireData({required this.pictureData, required this.newsData});
}
