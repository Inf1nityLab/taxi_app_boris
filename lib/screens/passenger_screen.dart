import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'driver_screen.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'booking_screen.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({Key? key}) : super(key: key);

  @override
  _PassengerScreenState createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _hiveService = HiveService();
  final _apiService = ApiService();
  List<Map<String, dynamic>> _allSchedules = [];
  List<UserModel> _drivers = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSchedules();
  }

  Future<void> _loadAllSchedules() async {
    try {
      print('Начало загрузки расписаний');
      final drivers = await _apiService.getDrivers();
      print('Получены водители: ${drivers.length}');
      _drivers = drivers;
      List<Map<String, dynamic>> allSchedules = [];

      for (var driver in drivers) {
        print('Загрузка расписаний для водителя: ${driver.name} (${driver.id})');
        final schedules = await _apiService.getDriverSchedules(driver.id);
        print('Получено расписаний для водителя ${driver.name}: ${schedules.length}');
        
        for (var schedule in schedules) {
          print('Расписание: ${schedule['date']} ${schedule['time']}');
          print('Маршрут: ${schedule['locationA']} - ${schedule['locationB']}');
          print('Клиенты: ${schedule['clients']?.length ?? 0}');
          
          schedule['driverName'] = driver.name;
          schedule['driverPhone'] = driver.phone;
          allSchedules.add(schedule);
        }
      }

      print('Всего загружено расписаний: ${allSchedules.length}');

      if (mounted) {
        setState(() {
          _allSchedules = allSchedules;
          _isLoading = false;
        });
        print('Состояние обновлено');
      }
    } catch (e) {
      print('Ошибка при загрузке расписаний: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке расписаний')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getSchedulesForSelectedDate() {
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    return _allSchedules
        .where((schedule) => schedule['date'] == dateStr)
        .toList();
  }

  Future<void> _checkDriverAndNavigate() async {
    final user = await _hiveService.getUser();
    if (user != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverScreen()),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  int _getAvailableSeats(Map<String, dynamic> schedule) {
    final clients = schedule['clients'] ?? [];
    final totalPassengers =
        clients.fold(0, (sum, client) => sum + (client['passengers'] as int));
    return (4 - totalPassengers).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesForDate = _getSchedulesForSelectedDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экран пассажира'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Стать водителем'),
              onTap: _checkDriverAndNavigate,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                EasyDateTimeLinePicker(
                  focusedDate: _selectedDate,
                  firstDate: DateTime(2024, 3, 18),
                  lastDate: DateTime(2030, 3, 18),
                  onDateChange: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                Expanded(
                  child: schedulesForDate.isEmpty
                      ? const Center(
                          child:
                              Text('Нет доступных поездок на выбранную дату'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: schedulesForDate.length,
                          itemBuilder: (context, index) {
                            final schedule = schedulesForDate[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${schedule['time']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Водитель: ${schedule['driverName']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Телефон: ${schedule['driverPhone']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Откуда: ${schedule['locationA']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Куда: ${schedule['locationB']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Свободных мест: ${_getAvailableSeats(schedule)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _getAvailableSeats(schedule) >
                                              0
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BookingScreen(
                                                          schedule: schedule),
                                                ),
                                              ).then(
                                                  (_) => _loadAllSchedules());
                                            }
                                          : null,
                                      child: const Text('Забронировать место'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
