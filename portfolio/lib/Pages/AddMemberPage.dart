import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:portfolio/Service/UserService.dart';
import '../Api/ApiRequest.dart';
import '../Models/User.dart';

class AddMemberPage extends StatefulWidget {
  final int projectId;

  AddMemberPage({required this.projectId});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {

  final TextEditingController _typeAheadController = TextEditingController();
  String? selectedUserId;
  String role = '';
  String contributions = '';
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }



  Future<void> fetchUsers() async {
    try {
      final response = await Dio().get('$api/Users');
      if (response.statusCode == 200) {
        final List<dynamic> fetchedUsers = response.data;
        setState(() {
          users = fetchedUsers.map((json) => User.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print(e.toString());
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

  void addMemberToProject() async {
    if (selectedUserId == null || role.isEmpty || contributions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Пожалуйста, заполните все поля')));
      return;
    }

    UserService userService = UserService();
    try {

      if (!kIsWeb) {
        final response = await Dio().post(
          '$api/UserProjects',
          data: {
            'userId': selectedUserId,
            'projectId': widget.projectId,
            'role': role,
            'contributions': contributions,
          },
        );


      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при добавленииq участника')));
      }
    }
      else{
        int? idCompanyProject = await getCompanyProjectIdByProjectId(
            widget.projectId);
        bool memberAdded = await userService.addCompanyProjectMember(
          idCompanyProject!,
          int.parse(selectedUserId!),
          role,
          contributions,
        );
        if (memberAdded) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка при добавленииq участника')));
        }
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при добавлении участника')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить участников')),
      body: SingleChildScrollView(
        child:  Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TypeAheadFormField<User?>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _typeAheadController,
                  decoration: InputDecoration(labelText: 'Пользователь'),
                ),
                suggestionsCallback: (pattern) {
                  return users.where((user) =>
                      user.fullName.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, User? suggestion) {
                  final user = suggestion!;
                  return ListTile(title: Text(user.fullName));
                },
                onSuggestionSelected: (User? suggestion) {
                  final user = suggestion!;
                  setState(() {
                    _typeAheadController.text = user.fullName; // Обновляем текст вручную
                    selectedUserId = user.id.toString();
                  });
                },
                noItemsFoundBuilder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Пользователь не найден'),
                ),
                getImmediateSuggestions: true, // Получать предложения сразу после фокуса
              ),


              SizedBox(height: 20),
              TextField(
                onChanged: (value) => role = value,
                decoration: InputDecoration(labelText: 'Роль'),
              ),
              SizedBox(height: 20),
              TextField(
                onChanged: (value) => contributions = value,
                decoration: InputDecoration(labelText: 'Вклад'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addMemberToProject,
                child: Text('Добавить'),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
