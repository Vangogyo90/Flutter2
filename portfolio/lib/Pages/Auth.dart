import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/User.dart';
import '../Api/ApiRequest.dart';
import 'Navigation.dart';
import 'Registration.dart';

TextEditingController _firstNameController = TextEditingController();
TextEditingController _lastNameController = TextEditingController();
TextEditingController _loginController = TextEditingController();
TextEditingController _passwordController = TextEditingController();

class Authorization extends StatefulWidget {
  const Authorization({super.key});

  @override
  State<Authorization> createState() => _AuthorizationState();
}

class _AuthorizationState extends State<Authorization> {
  bool _isObscure = true;
  late User user;

  Future<dynamic> fillUserDataByUserId() async {
    try {
      // Ваш существующий код для выполнения запроса
      final response = await dio.get('$api/Users/$IDUser');
      if (response.statusCode == 200) {
        final userData =
            response.data; // Получение данных пользователя из response.data

        user = User(
          id: userData['userId'],
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          email: userData['email'],
          // Добавьте остальные поля
        );

        // Здесь вы можете сделать что-то с объектом user, например, сохранить его в переменной класса _AuthorizationState
      } else {
        // Обработка ошибки или отображение заглушки
      }
    } catch (e) {
      throw Exception('Ошибка при выполнении запроса: $e');
    }
  }

  void _toggleObscure() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  void _showLoginMessage(String text) async {
    final snackBar = SnackBar(
        content: Text(
          text,
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80.0, left: 40.0, right: 40.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    if (text == 'Вход выполнен') {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
      prefs.setInt('userId', user.id);
      prefs.setString('firstName', user.firstName);
      prefs.setString('lastName', user.lastName);
      prefs.setString('email', user.email);
    }
  }

// Основная структура экрана
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center( // Центрирует содержимое по горизонтали и вертикали
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Центрирование содержимого по вертикали
                children: [
                  Spacer(flex: 2),
                  _buildLogo(),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1), // Установка отступов для контейнера
                    child: Column(
                      children: [
                        _buildTextField(_loginController, Icons.person, "Логин", false),
                        SizedBox(height: 20),
                        _buildTextField(_passwordController, Icons.lock, "Пароль", true),
                        SizedBox(height: 20),
                        _buildLoginButton(),
                        _buildRegisterButton(context),
                      ],
                    ),
                  ),
                  Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, IconData icon, String labelText, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  ElevatedButton _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      child: Text("Войти"),
      style: ElevatedButton.styleFrom(
        primary: Colors.blue,
        onPrimary: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
    );
  }

  TextButton _buildRegisterButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Registration())),
      child: Text(
        "Зарегистрироваться",
        style: TextStyle(color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildLogo() {
    return Text(
      "Ваше Портфолио",
      style: TextStyle(
        color: Colors.white,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  void _login() async {
    await request(_loginController.text, _passwordController.text);
    await getID(_loginController.text);
    await fillUserDataByUserId();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    prefs.setInt('userId', user.id);
    prefs.setString('firstName', user.firstName);
    prefs.setString('lastName', user.lastName);
    prefs.setString('email', user.email);
    _showLoginMessage('Вход выполнен');
    print("Login function executed");

    user = await getUserInfoFromSharedPreferences();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(user: user),
        fullscreenDialog: false, // Этот параметр скроет кнопку "назад"
      ),
    );
  }
}

Future<User> getUserInfoFromSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Здесь предполагается, что информация о пользователе была сохранена в SharedPreferences
  final int userId =
      prefs.getInt('userId') ?? 0; // Замените на ключ, который вы использовали
  IDUser = prefs.getInt('userId').toString() ??
      0.toString(); // Замените на ключ, который вы использовали
  final String firstName = prefs.getString('firstName') ?? '';
  final String lastName = prefs.getString('lastName') ?? '';
  final String email = prefs.getString('email') ?? '';

  return User(
    id: userId,
    firstName: firstName,
    lastName: lastName,
    email: email,
    // Добавьте остальные поля пользователя
  );
}
