import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/Models/CompanyProject.dart';
import 'package:portfolio/Pages/Profile.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../Api/ApiRequest.dart';
import '../Models/Application.dart';
import '../Models/Project.dart';
import '../Models/User.dart';
import '../Models/UserWithRole .dart';
import 'AddMemberPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProjectDetailsPage extends StatefulWidget {
  final Project project;
  final bool? isCompany;
  ProjectDetailsPage({required this.project,  this.isCompany});

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<UserWithRole> projectMembers = [];
  late Future<List<UserWithRole>> _projectMembersFuture;
  String _applicationStatus = '';

  Future<bool>? _isAdminFuture; // Добавьте Future переменную для хранения статуса админа
  bool? isCompany;


  @override
  void initState() {
    super.initState();
    fetchProjectMembers(widget.project.projectId);
    _isAdminFuture = isUserAdmin(widget.project.projectId); // Запускаем проверку на админа при инициализации
    isCompany = widget.isCompany;
    _fetchApplicationStatus(); // Вызываем метод при инициализации

  }

  // Метод для получения статуса заявки
  Future<void> _fetchApplicationStatus() async {
    int userID = int.parse(IDUser); // Предполагается, что IDUser - это строковое представление ID пользователя
    int projectID = widget.project.projectId;

    try {
      final response = await Dio().get('$api/Applications/StatusForUserProject/$userID/$projectID');
      if (response.statusCode == 200) {
        setState(() {
          _applicationStatus = response.data; // Прямое присвоение, т.к. ожидается, что response.data - это строка
        });
      } else {
        print('Failed to fetch application status');
      }
    } catch (e) {
      print('Error fetching application status: $e');
    }
  }


  Future<Image> _fetchPicture(String? pictureId) async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response = await _dio.get('$api/Pictures/$pictureId');
      if (response.statusCode == 200) {
        final photoData = response.data!;
        return Image.memory(Uint8List.fromList(photoData));
      } else {
        print('Failed to fetch picture data with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching picture data: $error');
    }
    return Image.asset('assets/images/placeholder_image.jpg');
  }



  Future<List<Project>> fetchAdminProjects() async {
    // Замените на ваше API-запрос для получения проектов администратора
    final response = await Dio().get('$api/UserProjects/AdminProjects');
    if (response.statusCode == 200) {
      return (response.data as List).map((project) => Project.fromJson(project)).toList();
    } else {
      throw Exception('Failed to load admin projects');
    }
  }
  Future<int?> getCompanyProjectIdByProjectId(int projectId) async {
    try {
      final response = await dio.get('$api/CompanyProjects/GetByProject/$projectId');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to fetch company project id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception when calling API: $e');
      return null;
    }
  }


  Future<void> fetchProjectMembers(int projectId) async {
    String endpoint;
    // Определение, какой endpoint использовать в зависимости от платформы
    if (kIsWeb) {
      int? idCompanyProject = await  getCompanyProjectIdByProjectId(projectId);
      if(idCompanyProject != null){
        endpoint = '$api/CompanyProjects/$idCompanyProject/members';
      }
      else{
        endpoint = '$api/UserProjects/ProjectMembers/$projectId';
      }
      // Endpoint для получения участников проекта компании
    } else {
      // Endpoint для получения участников проекта пользователя
      endpoint = '$api/UserProjects/ProjectMembers/$projectId';

    }

    try {
      final response = await Dio().get(endpoint);
      if (response.statusCode == 200) {
        final members = List<UserWithRole>.from(response.data.map((m) => UserWithRole.fromJson(m)));
        setState(() {
          projectMembers = members;
        });
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      print('Error fetching project members: $e');
    }
  }



  Future<bool> isUserAdmin( int projectId) async {
    bool isAdmin = false;
    String endpoint;

    // Определение контекста выполнения и выбор соответствующего endpoint
    if (kIsWeb) {
      // Предполагаем, что у вас есть специальный endpoint для проверки роли компании в проекте
      endpoint = '$api/Companies/CheckProjectAdmin/$CompanyID/$projectId';
    } else {
      // Для мобильной версии используйте существующий endpoint
      endpoint = '$api/UserProjects/CheckRole/$IDUser/$projectId';
    }

    try {
      final response = await Dio().get(endpoint);
      if (response.statusCode == 200) {
        final data = response.data;
        // Пример проверки роли; адаптируйте под формат вашего ответа
        isAdmin = data['role'] == 'Администратор';
      }
    } catch (e) {
      print('Ошибка при проверке роли: $e');
    }

    return isAdmin;
  }

  // Адаптированный метод для изменения роли участника проекта
  Future<bool> editProjectMemberRole(int projectId, int userId, String newRole, String contributions) async {
    String endpoint = kIsWeb ?
    '$api/CompanyProjectMembers/UpdateByUser/$userId' : // Endpoint для веба
    '$api/UserProjects/$projectId/$userId'; // Endpoint для мобильных устройств

    try {
      final response = await Dio().put(
        endpoint,
        data: {
          'role': newRole,
          'contributions': contributions,
        },
      );
      if (response.statusCode == 204) {
        print("Роль участника успешно обновлена");
        return true;
      } else {
        print("Ошибка при редактировании роли участника: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception when calling API: $e");
      return false;
    }
  }

  // Адаптированный метод для удаления участника проекта
  Future<bool> deleteProjectMember( int userId, int projectId) async {
    String endpoint = kIsWeb ?
    '$api/CompanyProjectMembers/DeleteByUser/$userId' : // Endpoint для веба
    '$api/UserProjects/$projectId/$userId'; // Endpoint для мобильных устройств

    try {
      Response response = await Dio().delete(endpoint);
      if (response.statusCode == 204) {
        print('Участник успешно удален');
        return true;
      } else {
        print('Ошибка при удалении участника: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка при удалении участника: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: <Widget>[
          FutureBuilder<bool>(
            future: _isAdminFuture,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!kIsWeb && snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
                // Если пользователь является администратором, показываем кнопки
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add_member') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddMemberPage(projectId: widget.project.projectId)),
                      ).then((value) {
                        // Проверяем, был ли участник добавлен
                        if (value == true) {
                          // Перезагружаем список участников, так как был добавлен новый участник
                          fetchProjectMembers(widget.project.projectId).then((_) {
                            setState(() {});
                          });
                        }
                      });

                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add_member',
                      child: Text('Добавить участников'),
                    ),
                  ],
                );
              }

              // Пользователь не админ, не показываем кнопку
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveBuilder(
              builder: (context, sizingInformation) {

                double aspectRatio = sizingInformation.isDesktop ? 3 / 1 : 16 / 9;
                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: widget.project.pictureId != null
                      ? FutureBuilder<Image>(
                    future: _fetchPicture(widget.project.pictureId.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: snapshot.data!.image,
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  )
                      : Container(
                    child: Center(child: Icon(Icons.image, size: 100)),
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.project.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Описание: ${widget.project.description}"),
                  SizedBox(height: 8),
                  Text("Начало: ${widget.project.startDate.toString().split(' ')[0]}"),
                  SizedBox(height: 8),
                  Text("Конец: ${widget.project.endDate.toString().split(' ')[0]}"),
                  SizedBox(height: 8),
                  InkWell(
                    child: Text("Ссылка на проект: ${widget.project.projectUrl}", style: TextStyle(color: Colors.blue)),
                    onTap: () {
                      // Add link handling here
                    },
                  ),

                  SizedBox(height: 8),
                  ResponsiveBuilder(
                    builder: (context, sizingInformation) {
                      if (!kIsWeb && isCompany == true) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Row(
                                children: [
                                  Text("Статус: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_applicationStatus.isNotEmpty ? _applicationStatus : "Нет заявки"),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _submitApplication(),
                              child: Text('Отправить заявку'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 16), // Добавляем небольшой отступ
                          ],
                        );
                      } else {
                        return SizedBox.shrink(); // На вебе кнопка не отображается
                      }
                    },
                  ),
                  Text("Участники", style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: projectMembers.length,
                    itemBuilder: (context, index) {
                      UserWithRole user = projectMembers[index];
                      // Исключаем отображение кнопок для пользователя с ролью "Администратор"
                      bool isNotAdmin = user.role != 'Администратор';
                      return ListTile(
                        title: Text('${user.firstName} ${user.lastName} ${user.middleName ?? ""}'),
                        subtitle: Text('${user.role} - ${user.contributions}'),
                        trailing: isNotAdmin ? FutureBuilder<bool>(
                          future: _isAdminFuture,
                          builder: (context, isAdminSnapshot) {
                            if (isAdminSnapshot.connectionState == ConnectionState.done && isAdminSnapshot.data == true) {
                              // Показываем кнопки редактирования и удаления только админу и не для администратора как участника
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () async {
                                      final Map<String, String?>? results = await _showEditRoleDialog(context, user.role, user.contributions);
                                      if (results != null) {
                                        String? newRole = results['role'];
                                        String? newContribution = results['contribution'];
                                        if (newRole != null && newContribution != null) {
                                          bool result = await editProjectMemberRole(widget.project.projectId, user.userId, newRole, newContribution);
                                          if (result) {
                                            // Роль участника успешно обновлена, обновляем список участников
                                            fetchProjectMembers(widget.project.projectId).then((_) {
                                              setState(() {});
                                            });
                                          }
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      bool result = await deleteProjectMember(user.userId, widget.project.projectId);
                                      if (result) {
                                        // Участник успешно удален, обновляем список участников
                                        fetchProjectMembers(widget.project.projectId).then((_) {
                                          setState(() {});
                                        });
                                      }
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Не показываем кнопки не-админам или для администратора как участника
                              return SizedBox.shrink();
                            }
                          },
                        ) : SizedBox.shrink(), // Не показываем кнопки для пользователя с ролью "Администратор"
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    final application = Application(
      userId: int.parse(IDUser), // ID пользователя, это значение должно быть получено из сессии или хранилища
      projectId: widget.project.projectId, // ID проекта компании, должен быть получен из текущего проекта
      status: 'Отправлена',
    );

    try {
      final response = await Dio().post(
        '$api/Applications', // Замените `$api` на фактический URL вашего API
        data: application.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Обработка успешного ответа
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Заявка успешно отправлена')),
        );
        setState(() {
          _applicationStatus = 'Отправлена'; // Обновляем статус заявки после успешной отправки
        });
      } else {
        // Обработка ошибки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке заявки')),
        );
      }
    } catch (e) {
      // Обработка исключения
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети при отправке заявки')),
      );
    }
  }



  Future<Map<String, String?>?> _showEditRoleDialog(BuildContext context, String currentRole, String currentContribution) async {
    TextEditingController roleController = TextEditingController(text: currentRole);
    TextEditingController contributionController = TextEditingController(text: currentContribution);

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Изменить роль и вклад'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleController,
                decoration: InputDecoration(hintText: "Введите новую роль"),
              ),
              SizedBox(height: 20),
              TextField(
                controller: contributionController,
                decoration: InputDecoration(hintText: "Введите вклад"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Сохранить'),
              onPressed: () {
                Navigator.of(context).pop({
                  'role': roleController.text,
                  'contribution': contributionController.text,
                });
              },
            ),
          ],
        );
      },
    );
  }

// Additional methods such as fetchProjectMembers, isUserAdmin, etc. go here
}
