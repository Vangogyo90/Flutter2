import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/Api/ApiRequest.dart';

import '../Models/User.dart';
import 'Auth.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Future<User> futureUser;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  String password = "";
  @override
  void initState() {
    super.initState();
    futureUser = fetchUser(IDUser).then((user) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _middleNameController.text = user.middleName ?? '';
      _emailController.text = user.email;
      _skillsController.text = user.skills ?? '';
      _educationController.text = user.education ?? '';
      _achievementsController.text = user.achievements ?? '';
      password = user.password!;
      return user;
    });
  }

  Future<User> fetchUser(String id) async {
    final response = await Dio().get('$api/Users/$id');

    if (response.statusCode == 200) {
      return User.fromJson(response.data);
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<void> updateUser(String id, User user) async {
    final response = await Dio().put(
      '$api/Users/$id',
      data: user.toJson(),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } else {
      throw Exception('Failed to update user');
    }
  }

  void showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
                TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
                TextFormField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name')),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextFormField(controller: _skillsController, decoration: const InputDecoration(labelText: 'Skills')),
                TextFormField(controller: _educationController, decoration: const InputDecoration(labelText: 'Education')),
                TextFormField(controller: _achievementsController, decoration: const InputDecoration(labelText: 'Achievements')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                User updatedUser = User(
                  id: int.parse(IDUser), // Assuming IDUser is available globally or passed to the widget
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  middleName: _middleNameController.text.isNotEmpty ? _middleNameController.text : null,
                  email: _emailController.text,
                  password: password,
                  skills: _skillsController.text.isNotEmpty ? _skillsController.text : null,
                  education: _educationController.text.isNotEmpty ? _educationController.text : null,
                  achievements: _achievementsController.text.isNotEmpty ? _achievementsController.text : null,
                );
                updateUser(IDUser, updatedUser).then((_) {
                  setState(() {
                    futureUser = Future.value(updatedUser);
                  });
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditDialog,
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView(
              children: <Widget>[
                ListTile(title: Text('ФИО: ${snapshot.data!.firstName} ${snapshot.data!.lastName} ${snapshot.data!.middleName ?? ""}')),
                ListTile(title: Text('Почта: ${snapshot.data!.email}')),
                ListTile(title: Text('Скилы: ${snapshot.data!.skills ?? "Нет информации"}')),
                ListTile(title: Text('Степень обучения: ${snapshot.data!.education ?? "Нет информации"}')),
                ListTile(title: Text('Достижения: ${snapshot.data!.achievements ?? "Нет информации"}')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const Authorization()),
                    );
                  },
                  child: const Text('Выход'),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No user data'));
          }
        },
      ),
    );
  }
}
