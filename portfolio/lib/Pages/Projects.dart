import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../Api/ApiRequest.dart';
import '../Models/Project.dart';
import 'ProjectDetailsPage.dart';

class ProjectPage extends StatefulWidget {
  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  Future<List<Project>> fetchAdminProjects() async {
    final response = await Dio().get('$api/UserProjects/AdminProjects');
    if (response.statusCode == 200) {
      return (response.data as List).map((project) => Project.fromJson(project)).toList();
    } else {
      throw Exception('Failed to load admin projects');
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
        print('Failed to fetch picture data with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching picture data: $error');
    }
    return Image.asset('assets/images/placeholder_image.jpg');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Проекты студентов'),
      ),
      body: FutureBuilder<List<Project>>(
        future: fetchAdminProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки проектов'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Проекты не найдены'));
          } else {
            return ResponsiveBuilder(
              builder: (context, sizingInformation) {
                var isMobile = sizingInformation.isMobile;
                var crossAxisCount = isMobile ? 1 : 3;
                var childAspectRatio = isMobile ? 1 / 1.2 : 3 / 2;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final project = snapshot.data![index];
                    return _buildProjectCard(context, project, isMobile);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, bool isMobile) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsPage(project: project)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch the cards in cross axis
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
              title: Text(project.title, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(project.description),
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
}
