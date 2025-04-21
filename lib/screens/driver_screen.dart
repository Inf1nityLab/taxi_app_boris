import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'passenger_screen.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'create_schedule_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final _hiveService = HiveService();
  final _apiService = ApiService();
  UserModel? _user;
  List<Map<String, dynamic>> _schedules = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Добавляем слушатель для обновления при возврате на экран
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final user = await _hiveService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
      if (user != null) {
        await _loadSchedules(user.id);
      }
    }
  }

  Future<void> _loadSchedules(String driverId) async {
    try {
      final schedules = await _apiService.getDriverSchedules(driverId);
      if (mounted) {
        setState(() {
          _schedules = schedules;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке расписаний: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке расписания')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getSchedulesForSelectedDate() {
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    return _schedules.where((schedule) => schedule['date'] == dateStr).toList();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы действительно хотите выйти из приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _hiveService.clearUser();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PassengerScreen()),
                );
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesForDate = _getSchedulesForSelectedDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экран водителя'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _user?.name ?? 'Пользователь',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Режим водителя',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Стать пассажиром'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PassengerScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Выйти'),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
      body: Column(
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
                    child: Text('Нет расписаний на выбранную дату'),
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
                                'Клиентов: ${schedule['clients'].length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (schedule['clients']?.isNotEmpty ?? false) ...[
                                const Text(
                                  'Пассажиры:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: schedule['clients'].length,
                                  itemBuilder: (context, clientIndex) {
                                    final client = schedule['clients'][clientIndex];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          client['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (client['comment']?.isNotEmpty ?? false)
                                              Text(
                                                'Комментарий: ${client['comment']}',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            Text(
                                              'Количество пассажиров: ${client['passengers']}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.phone),
                                          onPressed: () async {
                                            final Uri phoneUri = Uri(
                                              scheme: 'tel',
                                              path: client['phone'],
                                            );
                                            if (await canLaunchUrl(phoneUri)) {
                                              await launchUrl(phoneUri);
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Не удалось совершить звонок'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateScheduleScreen()),
          ).then((result) {
            if (result == true && _user != null) {
              _loadSchedules(_user!.id);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 