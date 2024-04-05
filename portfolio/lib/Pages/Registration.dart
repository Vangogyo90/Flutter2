import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/Models/Course.dart';
import 'package:portfolio/Models/Group.dart';

import '../Api/ApiRequest.dart';


TextEditingController _firstNameController = TextEditingController();
TextEditingController _lastNameController = TextEditingController();
TextEditingController _middleNameController = TextEditingController();
TextEditingController _emailController = TextEditingController();
TextEditingController _passwordController = TextEditingController();

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  bool _isObscure = true;
  List<Group> _groups = [];
  List<Course> _courses = [];
  String? _selectedGroup;
  String? _selectedCourse;
  int? _selectedGroupId;
  int? _selectedCourseId;
  bool? isWeb;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<Group> groups = await getGroups();
      List<Course> courses = await getCourses();
      setState(() {
        _groups = groups;
        _courses = courses;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _toggleObscure() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  void _navigateToAuthorization() {
    Navigator.pop(context);
  }

  void _showLoginMessage(String text) {
    final snackBar = SnackBar(
      content: Text(text,
        textAlign: TextAlign.center ,
      ),
      backgroundColor: Colors.green,  // Измените цвет фона
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80.0, left: 40.0, right: 40.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      /* padding: const EdgeInsets.fromLTRB(90.0, 16.0, 16.0, 0.0), // Внутренний отступ для поднятия*/
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    isWeb = MediaQuery.of(context).size.width > 800; // условная ширина для определения веб-платформы

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Регистрация',
          style: TextStyle(
            color: Colors.white, // Измените цвет текста заголовка
          ),
        ),
        backgroundColor: Colors.grey.shade900, // Измените цвет фона AppBar
      ),
      body: Container(
        color: Colors.grey.shade900, // Установите цвет фона для всего экрана
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildTextField(_firstNameController, 'Имя', Icons.person),
                  _buildTextField(_lastNameController, 'Фамилия', Icons.person),
                  _buildTextField(_middleNameController, 'Отчество', Icons.person),
                  _buildTextField(_emailController, 'Почта', Icons.email),
                  _buildPasswordField(_passwordController, 'Пароль', _isObscure),
                  _buildPasswordField(_passwordController, 'Подтвердите пароль', _isObscure),
                  if (!isWeb!) _buildDropdown("Группа", _groups), // Условное отображение
                  if (!isWeb!) _buildDropdown("Курс", _courses), // Условное отображение

                  ElevatedButton(
                    onPressed: () {
                      onRegisterButtonPressed();
                    },
                    child: Text(
                      'Зарегистрироваться',
                      style: TextStyle(
                        color: Colors.white, // Измените цвет текста кнопки
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue, // Измените цвет фона кнопки
                      onPrimary: Colors.white, // Измените цвет текста на кнопке
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? prefixIcon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          labelStyle: TextStyle(
            color: Colors.white, // Измените цвет текста метки
          ),
        ),
        style: TextStyle(
          color: Colors.white, // Измените цвет текста ввода
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscureText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleObscure,
          ),
          labelStyle: TextStyle(
            color: Colors.white, // Измените цвет текста метки
          ),
        ),
        style: TextStyle(
          color: Colors.white, // Измените цвет текста ввода
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: hint,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          labelStyle: TextStyle(
            color: Colors.white,
          ),
          filled: true,
          fillColor: Colors.grey.shade600,
        ),
        value: hint == "Группа" ? _selectedGroupId : _selectedCourseId,
        onChanged: (int? newValue) {
          setState(() {
            if (hint == "Группа") {
              _selectedGroupId = newValue;
            } else {
              _selectedCourseId = newValue;
            }
          });
        },
        items: items.map<DropdownMenuItem<int>>((item) {
          return DropdownMenuItem<int>(
            value: hint == "Группа" ? item.id : item.id, // Пример использования ID из item
            child: Text(hint == "Группа" ? item.name : item.number.toString()), // Пример использования name или number в зависимости от типа
          );
        }).toList(),
      ),
    );
  }
  // Предполагаем, что у вас есть кнопка регистрации, которая вызывает этот метод
  void onRegisterButtonPressed() {
  if(!isWeb!){
    if (_selectedGroupId == null || _selectedCourseId == null) {
      // Показать сообщение об ошибке, если какой-либо из ID не выбран
      _showLoginMessage('Пожалуйста, выберите группу и курс.');
      return; // Выйти из метода, если какие-то данные отсутствуют
    }

    // Продолжение, если все данные присутствуют
    registration(
      _firstNameController.text,
      _lastNameController.text,
      _middleNameController.text,
      _emailController.text,
      _passwordController.text,
      _selectedGroupId!, // Здесь безопасно использовать оператор `!`, так как выше мы убедились в наличии значения
      _selectedCourseId!, // Аналогично
    );
  } else{
    registrationWEB(
      _firstNameController.text,
      _lastNameController.text,
      _middleNameController.text,
      _emailController.text,
      _passwordController.text,
    );
  }
  }
}