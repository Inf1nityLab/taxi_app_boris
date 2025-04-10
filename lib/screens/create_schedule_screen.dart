import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import '../models/user_model.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({Key? key}) : super(key: key);

  @override
  _CreateScheduleScreenState createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationAController = TextEditingController();
  final _locationBController = TextEditingController();
  final _apiService = ApiService();
  final _hiveService = HiveService();

  DateTime _selectedDate = DateTime.now();
  int _selectedSeats = 1;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _locationAController.dispose();
    _locationBController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      final user = await _hiveService.getUser();
      if (user != null) {
        final schedule = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'date': DateFormat('dd.MM.yyyy').format(_selectedDate),
          'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'locationA': _locationAController.text,
          'locationB': _locationBController.text,
          'clients': [],
          'driverId': user.id,
        };

        await _apiService.createSchedule(user.id, schedule);
        
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать расписание'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 24),
              TextFormField(
                controller: _locationAController,
                decoration: const InputDecoration(
                  labelText: 'Откуда',
                  hintText: 'Введите начальную точку маршрута',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите начальную точку';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationBController,
                decoration: const InputDecoration(
                  labelText: 'Куда',
                  hintText: 'Введите конечную точку маршрута',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите конечную точку';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedSeats,
                decoration: const InputDecoration(
                  labelText: 'Количество мест',
                ),
                items: List.generate(10, (index) => index + 1)
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value мест'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSeats = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(
                  'Время: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSchedule,
                child: const Text('Создать расписание'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
