import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../Api/ApiRequest.dart';
import '../Models/CompanyProject.dart';
import '../Models/Project.dart';
import 'ProjectDetailsPage.dart';

class CompanyProjectPage extends StatefulWidget {
  @override
  _CompanyProjectPageState createState() => _CompanyProjectPageState();
}

class _CompanyProjectPageState extends State<CompanyProjectPage> {

  late Future<List<Project>> _projectsFuture;

  Future<List<Project>> fetchProjects() async {
    // Получение данных проектов компании
    final companyProjectsResponse = await Dio().get('$api/CompanyProjects');
    if (companyProjectsResponse.statusCode == 200) {
      List<CompanyProject> companyProjects = (companyProjectsResponse.data as List)
          .map((data) => CompanyProject.fromJson(data))
          .toList();

      // Загрузка деталей каждого проекта по projectId
      List<Project> projects = [];
      for (var companyProject in companyProjects) {
        final projectResponse = await Dio().get('$api/Projects/${companyProject.projectId}');
        if (projectResponse.statusCode == 200) {
          projects.add(Project.fromJson(projectResponse.data));
        }
      }
      return projects;
    } else {
      throw Exception('Failed to load company projects');
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
  void initState() {
    super.initState();
    _projectsFuture = fetchProjects();
  }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text('Проекты компании'),
       ),
       body: FutureBuilder<List<Project>>(
         future: _projectsFuture,
         builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return Center(child: CircularProgressIndicator());
           } else if (snapshot.hasError) {
             return Center(child: Text('Ошибка загрузки проектов компании'));
           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(child: Text('Проекты компании не найдены'));
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
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // Действие при нажатии на карточку, например, переход к детальному просмотру
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(project: project, isCompany: true),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: project.pictureId != null
                  ? FutureBuilder<Image>(
                future: _fetchPicture(project.pictureId.toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return Center(child: Icon(Icons.image, size: 100, color: Colors.grey));
                  }
                },
              )
                  : Center(child: Icon(Icons.image, size: 100, color: Colors.grey)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                project.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                project.description,
                style: TextStyle(fontSize: 14.0),
                maxLines: isMobile ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
           /* Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Начало: ${DateFormat('dd.MM.yyyy').format(project.startDate)}',
                    style: TextStyle(fontSize: 12.0),
                  ),
                  Text(
                    'Окончание: ${DateFormat('dd.MM.yyyy').format(project.endDate)}',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }

}
