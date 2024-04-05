import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Models/User.dart';
import 'Pages/Auth.dart';
import 'Pages/Navigation.dart';


String login="";
String password="";


var emails='';
var lastNames ='';
late User user;


// Вызываете функцию для выполнения GET-запроса и обработки данных.

void data_recording(){
  print(emails+' '+lastNames);
}

// сохранение сесси пользователя
void main() async {
  WidgetsFlutterBinding.ensureInitialized();




  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      final darkTheme = ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto Italic'),
        ),
      );
      return FutureBuilder<User>(
        future: getUserInfoFromSharedPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              user = snapshot.data!;
              return NavigationScreen(user: user);
            } else {
              return const CircularProgressIndicator();
            }
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    } else {
      return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,

        ),
        home: const Authorization(),
      );
    }
  }
}
