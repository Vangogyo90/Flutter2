import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../Api/ApiRequest.dart';
import '../Models/User.dart';
import 'Projects.dart';
import 'Company.dart';
import 'Profile.dart';


class NavigationScreen extends StatefulWidget {
  final User user;

  NavigationScreen({required this.user});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>{

  late TabController _tabController;
  int _selectedIndex = 0;

  late User user; // Используем "late" для отложенной инициализации

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CompanyProjectPage(),
      ProjectPage(),
      UserDetailsWidget(user: widget.user),
    ];
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

/*
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
*/



  Future<void> _initUserDataFromSharedPreferences() async {
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
    );

    setState(() {});
  }



  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return CompanyProjectPage();
      case 1:
        return ProjectPage();
      case 2:
        return UserDetailsWidget();
      default:
        return CompanyProjectPage(); // Можете вернуть пустой контейнер или другой экран по умолчанию
    }
  }


  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => _buildMobileLayout(),
      tablet: (BuildContext context) => _buildWebLayout(),
      desktop: (BuildContext context) => _buildWebLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.article), label: Text('Компании')),
              NavigationRailDestination(icon: Icon(Icons.message), label: Text('Проекты')),
              NavigationRailDestination(icon: Icon(Icons.person), label: Text('Профиль')),
            ],
          ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Компании'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Проекты'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }


}

