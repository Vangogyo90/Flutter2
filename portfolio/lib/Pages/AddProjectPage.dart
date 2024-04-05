import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../Api/ApiRequest.dart';
import '../Pages/Profile.dart';
import '../Service/NewsPuctireService.dart';
import '../Service/NewsService.dart';
import '../Service/ProjectUserService.dart';

class AddNews extends StatefulWidget {
  const AddNews({Key? key}) : super(key: key);

  @override
  _AddNewsState createState() => _AddNewsState();
}
bool? isWeb;
class _AddNewsState extends State<AddNews> {
  File? _selectedImage;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _projectURLController = TextEditingController();
TextEditingController _requirementsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  FormData? formData;
  Uint8List? _imageBytes;
  Response? response;
  Future<void> _selectImage() async {

    if (isWeb!) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.first.bytes != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;

        // Вызываем _uploadImage с новыми данными
        await _uploadImage(fileBytes, fileName);
        setState(() {
          _imageBytes = fileBytes;
        });
      }
    }
    else {
      final imagePicker = ImagePicker();
      final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        final croppedImage = await _cropImage(pickedImage.path);

        if (croppedImage != null) {
          setState(() {
            _selectedImage = croppedImage;
          });
        }
      }
    }
  }

  Future<void> _uploadImage(Uint8List fileBytes, String fileName) async {
    // Создаем новый экземпляр FormData прямо здесь
    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    try {
       response = await Dio().post(
        '$api/Pictures',
        data: formData,
      );
      if (response!.statusCode == 200 || response!.statusCode == 201) {
        // Обработка успешной загрузки
        print('Фото успешно загружено. ID фото: ${response!.data['idPicture']}');
      } else {
        // Обработка ошибки загрузки
        print('Ошибка при загрузке файла: ${response!.statusCode}');
      }
    } catch (e) {
      // Обработка исключения
      print('Ошибка при отправке файла: $e');
    }
  }

  Future<File?> _cropImage(String imagePath) async {
    final imageCropper = ImageCropper();

    final croppedImage = await imageCropper.cropImage(
      sourcePath: imagePath,
      aspectRatio: CropAspectRatio(
        ratioX: 16, // 1:1 aspect ratio
        ratioY: 9,
      ),
      compressQuality: 100, // Compression quality
      androidUiSettings: AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.deepOrange, // Toolbar color
        toolbarWidgetColor: Colors.white, // Toolbar icon color
        statusBarColor: Colors.deepOrange, // Status bar color
        backgroundColor: Colors.white, // Crop background color
      ),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
        aspectRatioLockDimensionSwapEnabled: false,
      ),
    );

    return croppedImage;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(), // текущая дата или уже выбранная дата
      firstDate: DateTime(2000), // минимально допустимая дата
      lastDate: DateTime(2025), // максимально допустимая дата
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(), // текущая дата или уже выбранная дата
      firstDate: DateTime(2000), // минимально допустимая дата
      lastDate: DateTime(2025), // максимально допустимая дата
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }


  Future<void> _addNews() async {
    try {

    int? pictureId;

      if(isWeb!){
        try {
    /*    // Загружаем файл на сервер
        Response response = await Dio().post(
          '$api/Pictures', // Убедитесь, что $api содержит корректный базовый URL вашего API
          data: formData,
        );*/

        if (response!.statusCode == 200 || response!.statusCode == 201) {
          print('Файл успешно загружен');
          // Здесь можно обновить UI или состояние в зависимости от ответа сервера
          pictureId = response!.data['idPicture'];

        } else {
          print('Ошибка при загрузке файла: ${response!.statusCode}');
        }
      } catch (e) {
        print('Ошибка при отправке файла: $e');
      }
      }
      else{
   
      final List<int> bytes = await _selectedImage!.readAsBytes();

    /*  FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'user_photo.jpg'),
      });

      Response response = await dio.post(
        '$api/Pictures',
        data: formData,
      );*/
/*
         if (response!.statusCode == 201 || response.statusCode == 200) {
        print('Фото успешно загружено. ID фото: ${response.data['idPicture']}');
      } else {
        print('Ошибка при загрузке фото: ${response.statusCode}');
        return;
      }*/

/*
       pictureId = response.data['idPicture'];
*/
      }


      Map<String, dynamic> newsResponse = await NewsService().postNews(
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: _startDate!.toIso8601String(), // Преобразование DateTime в строку
        endDate: _endDate!.toIso8601String(), // Преобразование DateTime в строку
        projectUrl: _projectURLController.text,
        pictureId: pictureId!,
      );

      int projectId = newsResponse['projectId'];

      await NewsPuctireService().postNewsPuctire(
        pictureId: pictureId,
        projectId: projectId,
      );

      if (isWeb!) {
        if(CompanyID! != null){
          await addCompanyProject(CompanyID!, projectId, _requirementsController.text);
        }
        else{
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Сначала добавьте проект!'),
              duration: Duration(seconds: 2),
            ),
      );
        }
      }
      else{
        await ProjectUserService().postProjectUser(
        userId: int.parse(IDUser),
        projectId: projectId,
      );
      }

      // Add any additional logic or UI updates as needed
    } catch (e) {
      print('Error adding news: $e');
    }
  }

Future<void> addCompanyProject(int companyId, int projectId, String requirements) async {
  try {
    Response response = await Dio().post(
      '$api/CompanyProjects', // Укажите здесь фактический URL API для CompanyProjects
      data: {
        'companyId': companyId,
        'projectId': projectId,
        'requirements': requirements,
      },
    );

    if (response.statusCode == 201) {
      print('Проект компании успешно добавлен');
    } else {
      print('Ошибка при добавлении проекта компании: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при добавлении проекта компании: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600; // или другое условие для определения веб-платформы
    // Адаптивные размеры и стили
    final double imageWidth = isWeb! ? 200.0 : double.infinity; // Задаем ширину для веба
    double containerWidth = isWeb! ? 600 : double.infinity; // Максимальная ширина контейнера на вебе
    double imageHeight = 200; // Фиксированная высота изображения
    double padding = isWeb! ? 20 : 8; // Отступ для веба и мобильных устройств
    EdgeInsets contentPadding = isWeb! ? const EdgeInsets.all(20) : const EdgeInsets.all(8);

    return Scaffold(
  
      appBar: AppBar(
        title: Text('Создать проект'),
      ),
      body: SingleChildScrollView(
      child: Padding(
      padding: contentPadding,
      child: Center( // Центрирование для веба
        child: Container(
          width: containerWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _getImageWidget(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Название проекта'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Описание проекта', maxLines: 3),
              if (isWeb!) _buildTextField(_requirementsController, 'Требования проекта', maxLines: 3),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectStartDate(context),
                child: Text('Выбрать дату начала'),
              ),
              if (_startDate != null) Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Выбранная дата начала: ${_startDate!.toIso8601String().split('T').first}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectEndDate(context),
                child: Text('Выбрать дату окончания'),
              ),
              if (_endDate != null) Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Выбранная дата окончания: ${_endDate!.toIso8601String().split('T').first}'),
              ),
              const SizedBox(height: 16),
              _buildTextField(_projectURLController, 'URL проекта'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addNews,
                child: Text('Создать проект'),
              ),
            ],
          ),
        ),
      ) ,

    )));
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _getImageWidget() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else {
      return Icon(Icons.add_a_photo, size: 50);
    }
  }
}
