import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:portfolio/Pages/AddProjectPage.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api/ApiRequest.dart';
import '../Models/Application.dart';
import '../Models/Company.dart';
import '../Models/Project.dart';
import '../Models/User.dart';
import '../Service/UserService.dart';
import 'Auth.dart';
import '../main.dart';
import 'ProjectDetailsPage.dart';
import 'SettingsPage.dart';

class UserDetailsWidget extends StatefulWidget {
  final User? user;



  const UserDetailsWidget({super.key, /*required*/ this.user});

  @override
  _UserDetailsWidgetState createState() => _UserDetailsWidgetState();
}
int? CompanyID;
List<Image> photoImages = [];
class _UserDetailsWidgetState extends State<UserDetailsWidget> {
    late Future<Company?> _companyFuture;

  List<Project> _userProjects = [];
   Future<List<Project>>? _projectsCompany;

  List<Uint8List> photoAllImages = [];
  List<Map<String, dynamic>> newsData = []; // Добавляем здесь

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getUserInfoFromPrefs();
    UserInfo();   
      // loadData();
    //  fetchCompanyByUserId(int.parse(IDUser));
    if(kIsWeb == false) {
    fetchUserProjects(int.parse(IDUser));
    }
        _companyFuture = fetchCompanyByUserId(int.parse(IDUser)); // Инициализируйте запрос здесь

    // fetchProjects(CompanyID!);

  }
//   Future<void> loadData() async {
//   await Future.wait([
//     fetchCompanyByUserId(int.parse(IDUser)),
//   ]);
//   _loadProjects(); 
// }


  void UserInfo(){
    _fetchUserPhotos();
    // _fetchUserNews();
  }

    void  _loadProjects() {
    _projectsCompany =  fetchProjects(int.parse(IDUser), kIsWeb);
  }

  Future<void> _getUserInfoFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int userId = prefs.getInt('userId') ?? 0;
    final String firstName = prefs.getString('firstName') ?? '';
    final String lastName = prefs.getString('lastName') ?? '';
    final String email = prefs.getString('email') ?? '';

    user = User(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      // Добавьте остальные поля пользователя
    );

    setState(() {});
  }

  Future<List<Project>> fetchUserProjects(int userId) async {
    try {
      final Dio dio = Dio();
      dio.options.responseType = ResponseType.json;
      final response = await dio.get('$api/Users/UserProjects/$userId');

      if (response.statusCode == 200) {
        final List projectsJson = response.data;
        List<Project> projects = projectsJson.map((json) => Project.fromJson(json)).toList();
        return projects; // Возвращаем список проектов напрямую
      } else {
        print('Failed to fetch user projects with status code: ${response.statusCode}');
        return []; // Возвращаем пустой список в случае ошибки
      }
    } catch (error) {
      print('Error: $error');
      return []; // Возвращаем пустой список в случае исключения
    }
  }


  Future<void> uploadUserPhoto(int userId, File imageFile) async {
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Users/upload-photo/$userId',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('Фото успешно загружено. ID фото: ${response.data['photoID']}');
        // Обновите список фотографий с сервера или выполните другие действия
      } else {
        print('Ошибка при загрузке фото: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке фото: $e');
    }
  }


  Future<void> _selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final croppedImage = await _cropImage(pickedImage.path);

      if (croppedImage != null) {
        setState(() {
          final image = Image.file(croppedImage, fit: BoxFit.cover);
          photoImages.add(image);
        });

        // Теперь загрузите обрезанное фото на сервер и обновите логику загрузки
        await uploadUserPhoto(int.parse(IDUser), croppedImage);
      }
    }
  }

    Future<File?> _cropImage(String imagePath) async {
      final imageCropper = ImageCropper();

      final croppedImage = await imageCropper.cropImage(
        sourcePath: imagePath,
        aspectRatio: CropAspectRatio(
          ratioX: 1, // 1:1 aspect ratio
          ratioY: 1,
        ),
        compressQuality: 100, // Compression quality
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange, // Цвет панели инструментов
          toolbarWidgetColor: Colors.white, // Цвет иконок на панели инструментов
          statusBarColor: Colors.deepOrange, // Цвет статус-бара
          backgroundColor: Colors.white, // Цвет фона обрезки
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
          aspectRatioLockDimensionSwapEnabled: false,
        ),
      );

      return croppedImage;
    }

  Future<void> _fetchUserPhotos() async {
    try {

      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response = await _dio.get('$api/Users/user-photos/$IDUser');
      if (response.statusCode == 200) {
        final photoData = response.data;
        setState(() {
          final image = Image.memory(Uint8List.fromList(photoData!));
          photoImages.add(image);
        });
      } else {
        // Обработка ошибки
        print('Failed to fetch user photos with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<List<int>> _fetchUserAppPhotos(int idUser) async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response = await _dio.get('$api/Users/user-photos/$idUser');
      if (response.statusCode == 200 && response.data != null) {
        // Возвращаем данные фотографии напрямую
        return response.data!;
      } else {
        // В случае ошибки возвращаем пустой список
        print('Failed to fetch user photos with status code: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching user photos: $error');
      return [];
    }
  }


  Future<void> _selectImages() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final croppedImage = await _cropImage(pickedImage.path);

      if (croppedImage != null) {
        final imageBytes = await croppedImage.readAsBytes();

        setState(() {
          photoAllImages.add(Uint8List.fromList(imageBytes));
        });

        // Now, upload the cropped image to the server and update the upload logic
        await uploadUserPhotos(int.parse(IDUser), croppedImage);
        _fetchUserPhotoses();
      }
    }
  }

  Future<void> _fetchUserPhotoses() async {
    try {
      print('Fetching user photos...');

      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.json;
      Response response = await _dio.get('$api/Users/user-photoses/$IDUser');

      if (response.statusCode == 200) {
        final photos = response.data;
        List<Uint8List> images = []; // Change the type to Uint8List

        for (var photoData in photos) {
          final photoDataBytes = base64.decode(photoData);
          images.add(Uint8List.fromList(photoDataBytes));
          print('Added an image to the list');
        }

        setState(() {
          photoAllImages.clear();
          photoAllImages.addAll(images);
        });
      } else {
        // Handle error
        print('Failed to fetch user photos with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> uploadUserPhotos(int userId, File imageFile) async {
    try {
      final List<int> bytes = imageFile.readAsBytesSync();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Users/upload-photos/$userId',
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Adjust this part based on the actual response structure
        if (responseData.containsKey('photoID')) {
          print('Фото успешно загружено. ID фото: ${responseData['photoID']}');
          // Обновите список фотографий с сервера или выполните другие действия
        } else {
          print('Ошибка при загрузке фото: Неверный формат ответа');
        }
      } else {
        print('Ошибка при загрузке фото: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке фото: $e');
    }
  }

  Future<Image> _fetchPicture(String? pictureId) async {
    try {
      final Dio _dio = Dio();
      _dio.options.responseType = ResponseType.bytes;
      Response<List<int>> response = await _dio.get('$api/Pictures/$pictureId');
      if (response.statusCode == 200) {
        final photoData = response.data;
        final image = Image.memory(Uint8List.fromList(photoData!));
        return image;
      } else {
        // Обработка ошибки
        print('Failed to fetch picture data with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching picture data: $error');
    }

    // Если изображение не найдено, вернуть пустой контейнер или другое запасное изображение
    return Image.asset('assets/images/placeholder_image.jpg');
  }

  Future<String> getUserRoleForProject(int userId, int projectId) async {
    final response = await Dio().get('$api/UserProjects/CheckRole/$userId/$projectId');
    if (response.statusCode == 200 && response.data != null) {
      return response.data['role'];
    } else {
      return 'Нет доступа';
    }
  }
// Future<void> checkCompanyRoleInProject() async {
//     // String role = await fetchCompanyProjectsRoles(proj, CompanyID!);
//     // if (role == "Администратор") {
//     //   // Отобразить элементы управления для администратора
//     // }
  
// }

  Future<String> fetchCompanyProjectsRoles(int projectId, int companyId) async {
    final response = await Dio().get(
        '$api/Companies/CheckProjectAdmin/$companyId/$projectId');

    if (response.statusCode == 200 && response.data != null) {
      return response.data['role'];
    } else {
      return 'Нет доступа';
    }
  }

  Future<Company?> fetchCompanyByUserId(int userId) async {
    final response = await Dio().get('$api/Companies/ByUser/$userId');
    if (response.statusCode == 200 && response.data != null) {
      
       setState(() {
      CompanyID = response.data['companyId'];
      _loadProjects(); // Переместите вызов сюда, чтобы гарантировать, что CompanyID установлен
    });
      return Company.fromJson(response.data);
    } else {
      return null; // Возвращаем null, если компания не найдена
    }
  }

  Future<bool> editCompany(int companyId, String name, String contactInfo) async {
    try {
      final response = await Dio().put(
        '$api/Companies/$companyId',
        data: {
          'companyId': companyId,
          'companyName': name,
          'contactInfo': contactInfo,
          'userId': IDUser,
        },
      );
     
      return response.statusCode == 204;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deleteCompany(int companyId) async {
    try {
      final response = await Dio().delete('$api/Companies/$companyId');
      return response.statusCode == 204;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Future<List<Project>> fetchCompanyProjects(int companyId) async {
  //   final response = await Dio().get('$api/CompanyProjects/$CompanyID');
  //   if (response.statusCode == 200) {
  //     final List projectsJson = response.data;
  //     return projectsJson.map((json) => Project.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load company projects');
  //   }
  // }

  Future<List<Project>> fetchProjects(int userId, bool kIsWeb) async {
    try {
      final endpoint = kIsWeb ? '$api/Companies/CompanyProjects/$CompanyID' : '$api/Users/UserProjects/$userId';
      final Dio dio = Dio();
      dio.options.responseType = ResponseType.json;
      final response = await dio.get(endpoint);

      if (response.statusCode == 200) {
        List<dynamic> projectsJson = response.data is List ? response.data : [response.data];
        List<Project> projects = projectsJson.map((json) => Project.fromJson(json)).toList();

        return projects;
      } else {
        print('Failed to fetch projects with status code: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error: $error');
      return [];
    }
  }

  Future<List<Application>> fetchApplications() async {
    final Dio dio = Dio();
    final response = await dio.get('$api/Applications');

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Application.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load applications');
    }
  }

  Future<User?> getUserData(int userId) async {
    try {
      final response = await dio.get('$api/Users/$userId');
      if (response.statusCode == 200) {
        // Если запрос успешен, разбираем JSON и возвращаем объект User
        return User.fromJson(response.data);
      } else {
        // Обработка ошибок запроса
        print('Error fetching user data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Обработка исключений, например, при отсутствии сетевого соединения
      print('Exception when calling API: $e');
      return null;
    }
  }

  Future<Project?> fetchProject(int projectId) async {
    try {
      final response = await Dio().get('$api/Projects/$projectId');
      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        print('Failed to fetch project with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching project: $e');
      return null;
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

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: DefaultTabController(
        length: kIsWeb ? 3:2, // Количество вкладок
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text("Профиль"),
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) =>
                [
                  PopupMenuItem(
                    child: Text('Создать проект'),
                    value: 'addproject',
                  ),
                  PopupMenuItem(
                    child: Text('Настройки'),
                    value: 'settings',
                  ),
                ],
                onSelected: (value) {
                  if (value == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Settings()),
                    );
                  }
                  if (value == 'addproject') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddNews())
                    );
                  }
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              bool kIsWeb = constraints.maxWidth > 600; // Определение, является ли устройство вебом

              return Column(
                children: [
                  // Создание адаптивного макета для веба и мобильных устройств
                  kIsWeb
                      ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _selectImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: ClipOval(
                                  child: photoImages.isNotEmpty
                                      ? photoImages.last
                                      : Icon(Icons.add_a_photo),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    user.lastName +' '+ user.firstName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${user.email}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FutureBuilder<Company?>(
                            future: _companyFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Показываем индикатор загрузки
                              } else if (snapshot.hasData) {
                                Company company = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Данные о компании',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      company.companyName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(company.contactInfo),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Вызовите функцию для редактирования данных компании
                                            showEditCompanyDialog(company);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            // Вызовите функцию для удаления данных компании
                                            showDeleteCompanyDialog(company.companyId);
                                          },
                                        ),

                                      ],
                                    ),
                                  ],
                                );

                              } else {
                                return Align(
                                  alignment: Alignment.centerLeft, // Выравниваем кнопку слева
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints.tightFor(width: 200, height: 40), // Ограничиваем размер кнопки
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showAddCompanyDialog(context);
                                      },
                                      child: Text('Добавить компанию', style: TextStyle(fontSize: 16, color: Colors.white),), // Уменьшаем размер текста
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.blueAccent, // Цвет фона кнопки
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20), // Закругление углов кнопки
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Уменьшаем внутренние отступы
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                    ],
                  )
                      : Column(
                    children: [
                      GestureDetector(
                        onTap: _selectImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: ClipOval(
                            child: photoImages.isNotEmpty
                                ? photoImages.last
                                : Icon(Icons.add_a_photo),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              user.lastName +' '+ user.firstName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${user.email}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TabBar(
                    tabs: [
                      Tab(text: 'Мои проекты'),
                      Tab(text: 'Участие'),
                      if (kIsWeb) Tab(text: 'Заявки'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMyProjectsWidget(), // Виджет для отображения ваших проектов
                        _buildParticipationWidget(),
                        if (kIsWeb) _buildApplicationsWidget(), // Виджет для отображения участия
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildApplicationsWidget() {
    return FutureBuilder<List<Application>>(
      future: fetchApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки заявок'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Заявки не найдены'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final application = snapshot.data![index];
              return FutureBuilder<User?>(
                future: getUserData(application.userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
                    final user = userSnapshot.data!;
                    return FutureBuilder<List<int>>(
                      future: _fetchUserAppPhotos(user.id),
                      builder: (context, photoSnapshot) {
                        if (photoSnapshot.connectionState == ConnectionState.done && photoSnapshot.hasData) {
                          return FutureBuilder<Project?>(
                            future: fetchProject(application.projectId),
                            builder: (context, projectSnapshot) {
                              if (projectSnapshot.connectionState == ConnectionState.done && projectSnapshot.hasData) {
                                final project = projectSnapshot.data!;
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: MemoryImage(Uint8List.fromList(photoSnapshot.data!)),
                                    ),
                                    title: Text('${user.firstName} ${user.lastName}'),
                                    subtitle: Text('Проект: ${project.title}'),
                                    onTap: () => _showUserDetailsDialog(context, user, project, Uint8List.fromList(photoSnapshot.data!), application.applicationId!),
                                  ),
                                );
                              } else {
                                return Center(child: CircularProgressIndicator());
                              }
                            },
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  void _showUserDetailsDialog(BuildContext context, User user, Project project, Uint8List userPhoto, int applicationId) {

    TextEditingController roleController = TextEditingController();
    TextEditingController contributionsController = TextEditingController();
    UserService userService = UserService();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Информация о пользователе'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ClipOval(
                  child: Container(
                    width: 100.0, // Укажите ширину для квадрата
                    height: 300.0, // Укажите высоту для квадрата
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover, // Это гарантирует, что изображение будет заполнять область
                        image: MemoryImage(userPhoto),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text('Фамилия: ${user.firstName}'),
                Text('Имя: ${user.lastName}'),
                if (user.middleName != null) Text('Отчество: ${user.middleName}'),
                Text('Email: ${user.email}'),
                Text('Достижения: ${user.achievements}'),
                Text('Образование: ${user.education}'),
                Text('Умения: ${user.skills}'),
                SizedBox(height: 10),
                Text('Проект: ${project.title}'),
                Text('Описание проекта: ${project.description}'),
                TextField(
                  controller: roleController,
                  decoration: InputDecoration(hintText: 'Роль в проекте'),
                ),
                TextField(
                  controller: contributionsController,
                  decoration: InputDecoration(hintText: 'Вклад в проект'),
                ),
                // Дополнительная информация о проекте и пользователе
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Принять'),
              onPressed: () async {
                // Обновляем статус заявки и добавляем пользователя в проект
                bool statusUpdated = await userService.updateApplicationStatus( applicationId, 'Принята', user.id, project.projectId);
                int? idCompanyProject = await getCompanyProjectIdByProjectId(project.projectId);
                bool memberAdded = await userService.addCompanyProjectMember(
                  idCompanyProject!,
                  user.id,
                  roleController.text,
                  contributionsController.text,
                );

                if (statusUpdated && memberAdded) {

                    Navigator.of(context).pop();

                } else {
                  // Обработка ошибок
                }
              },
            ),
            TextButton(
              child: Text('Отклонить'),
              onPressed: () async {
                // Обновляем статус заявки
                bool statusUpdated = await userService.updateApplicationStatus(applicationId, 'Отклонена', user.id, project.projectId);
                if (statusUpdated) {

                    Navigator.of(context).pop();

                } else {
                  // Обработка ошибок
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyProjectsWidget()  {
    return  FutureBuilder<List<Project>> (
      future:  fetchProjects(int.parse(IDUser), kIsWeb),
      builder: (context, projectSnapshot)  {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (projectSnapshot.hasError) {
          return Center(child: Text('Ошибка загрузки проектов'));
        } else if (!projectSnapshot.hasData || projectSnapshot.data!.isEmpty) {
          return Center(child: Text('Проекты не найдены'));
        } else {
          // Используем ResponsiveBuilder для адаптивного отображения
          return ResponsiveBuilder(
            builder: (context, sizingInformation) {
              var isMobile = sizingInformation.isMobile;
              var crossAxisCount = isMobile ? 1 : 3; // Количество элементов в строке
              var childAspectRatio = isMobile ? 1 / 1.2 : 3 / 2; // Соотношение сторон карточки

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: projectSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final project = projectSnapshot.data![index];
                  return FutureBuilder<dynamic>(
                    future: kIsWeb ? fetchCompanyProjectsRoles(project.projectId, CompanyID!) : getUserRoleForProject(int.parse(IDUser),project.projectId),
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.connectionState == ConnectionState.waiting) {
                        return Container(); // или виджет загрузки, если нужно
                      } else if (roleSnapshot.hasData && roleSnapshot.data == 'Администратор') {
                        // Пользователь является администратором, отображаем проект
                        return _buildProjectCard(project, isMobile); // Обновите _buildProjectCard для поддержки isMobile
                      } else {
                        return Container(); // Проект не отображается, если пользователь не администратор
                      }
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }


  Widget _buildProjectCard(Project project, bool isMobile) {
    // Адаптируем отступы и размеры в зависимости от устройства
    double imageAspectRatio = isMobile ? 16 / 9 : 3 / 2;
    EdgeInsets cardMargin = EdgeInsets.all(8.0);
    TextStyle titleStyle = TextStyle(
      fontSize: isMobile ? 16.0 : 20.0,
      fontWeight: FontWeight.bold,
    );
    TextStyle descriptionStyle = TextStyle(
      fontSize: isMobile ? 14.0 : 16.0,
    );

    return Card(
      margin: cardMargin,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsPage(project: project)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: FutureBuilder<Image>(
                future: _fetchPicture(project.pictureId.toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return Center(child: Icon(Icons.image, size: 100, color: Colors.grey));
                  }
                },
              ),
            ),
            ListTile(
              title: Text(project.title, style: titleStyle),
              subtitle: Text(project.description),
              // Убираем кнопку "Подробнее" для веб-версии
              trailing: isMobile ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProjectDetailsPage(project: project)),
                  );
                },
                child: Text('Подробнее'),
              ) : null,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildParticipationWidget() {
    // Замените `fetchParticipatedProjects` на ваш метод загрузки проектов, где пользователь участвует
    return FutureBuilder<List<Project>>(
      future: fetchParticipatedProjects(int.parse(IDUser)), // Здесь используйте метод для загрузки участвующих проектов
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки проектов'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Участие в проектах не найдено'));
        } else {
          // Используем ResponsiveBuilder для адаптивного отображения
          return ResponsiveBuilder(
            builder: (context, sizingInformation) {
              var isMobile = sizingInformation.isMobile;
              var crossAxisCount = isMobile ? 1 : 3; // Количество элементов в строке для GridView
              var childAspectRatio = isMobile ? 1 / 1.2 : 3 / 2; // Соотношение сторон для GridView

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final project = snapshot.data![index];
                  // Обратите внимание, что здесь передается аргумент isMobile
                  return _buildProjectCard(project, isMobile); // Используйте этот метод для построения карточки проекта
                },
              );
            },
          );
        }
      },
    );
  }



  Future<List<Project>> fetchParticipatedProjects(int userId) async {
    final response = await Dio().get('$api/UserProjects/UserParticipation/$userId');
    if (response.statusCode == 200) {
      final List projectsJson = response.data;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load participated projects');
    }
  }


  void showAddCompanyDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController contactInfoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить компанию'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Название компании'),
                ),
                TextField(
                  controller: contactInfoController,
                  decoration: InputDecoration(hintText: 'Контактная информация'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалоговое окно
              },
            ),
            TextButton(
              child: Text('Добавить'),
              onPressed: () {
                // Вызываем функцию создания компании и передаем введенные данные
                createCompany(nameController.text, contactInfoController.text)
                    .then((company) {
                  if (company != null) {
                    Navigator.of(context).pop(); // Закрываем диалоговое окно при успешном создании
                  } else {
                    // Можно отобразить сообщение об ошибке
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }


  void showEditCompanyDialog(Company company) {
    TextEditingController nameController = TextEditingController(text: company.companyName);
    TextEditingController contactInfoController = TextEditingController(text: company.contactInfo);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать компанию'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Название компании'),
                ),
                TextField(
                  controller: contactInfoController,
                  decoration: InputDecoration(hintText: 'Контактная информация'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалоговое окно
              },
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: () {
                // Вызываем функцию для обновления данных компании
                editCompany(company.companyId, nameController.text, contactInfoController.text).then((success) {
                  if (success) {
                    Navigator.of(context).pop();
                    setState(() {
                      fetchCompanyByUserId(int.parse(IDUser));
                    });// Закрываем диалоговое окно при успешном обновлении
                  } else {
                    // Можно отобразить сообщение об ошибке
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteCompanyDialog(int companyId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удалить компанию?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Вы уверены, что хотите удалить эту компанию?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалоговое окно
              },
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () {
                deleteCompany(companyId).then((success) {
                  if (success) {
                    Navigator.of(context).pop(); // Закрываем диалоговое окно при успешном удалении
                  } else {
                    // Можно отобразить сообщение об ошибке
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
}


