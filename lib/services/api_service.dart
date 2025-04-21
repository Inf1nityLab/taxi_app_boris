import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'https://670ba1247e5a228ec1ce1ca9.mockapi.io';
  static const String driversEndpoint = '$baseUrl/drivers';
  static const String scheduleEndpoint = '$baseUrl/drivers';

  Future<List<UserModel>> getDrivers() async {
    print('Запрос списка водителей');
    final response = await http.get(
      Uri.parse(driversEndpoint),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    print('Ответ от сервера (водители): ${response.statusCode}');
    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      print('Тело ответа (водители): $responseBody');
      List<dynamic> data = json.decode(responseBody);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      print('Ошибка при получении водителей: ${response.statusCode}');
      throw Exception('Failed to load drivers');
    }
  }

  Future<UserModel> authenticateUser(String email, String password) async {
    final drivers = await getDrivers();
    try {
      return drivers.firstWhere(
        (driver) => driver.email == email && driver.password == password,
      );
    } catch (e) {
      throw Exception('Driver not found');
    }
  }

  Future<void> createDriver(UserModel driver) async {
    final response = await http.post(
      Uri.parse(driversEndpoint),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode(driver.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create driver');
    }
  }

  Future<void> updateDriver(UserModel driver) async {
    final response = await http.put(
      Uri.parse('$driversEndpoint/${driver.id}'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode(driver.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update driver');
    }
  }

  Future<List<Map<String, dynamic>>> getDriverSchedules(String driverId) async {
    print('Запрос расписаний для водителя: $driverId');
    final response = await http.get(
      Uri.parse('$scheduleEndpoint/$driverId/schedule'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    print('Ответ от сервера (расписания): ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      print('Тело ответа (расписания): $responseBody');
      return List<Map<String, dynamic>>.from(json.decode(responseBody));
    } else if (response.statusCode == 404) {
      // Если расписаний нет, возвращаем пустой список
      print('Расписаний для водителя $driverId не найдено');
      return [];
    } else {
      print('Ошибка при получении расписаний: ${response.statusCode}');
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> createSchedule(String driverId, Map<String, dynamic> schedule) async {
    final response = await http.post(
      Uri.parse('$scheduleEndpoint/$driverId/schedule'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode(schedule),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create schedule');
    }
  }

  Future<void> updateSchedule(String driverId, String scheduleId, Map<String, dynamic> schedule) async {
    final response = await http.put(
      Uri.parse('$scheduleEndpoint/$driverId/schedule/$scheduleId'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode(schedule),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update schedule');
    }
  }
} 