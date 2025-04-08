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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _toController = TextEditingController();
  final _timeController = TextEditingController();
  final _apiService = ApiService();
  final _hiveService = HiveService();

  DateTime _selectedDate = DateTime.now();
  int _selectedSeats = 1;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _toController.dispose();
    _timeController.dispose();
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
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      final user = await _hiveService.getUser();
      if (user != null) {
        final schedule = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'date': _selectedDate.toIso8601String(),
          'time': _timeController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'to': _toController.text,
          'seats': _selectedSeats,
        };

        final updatedUser = UserModel(
          id: user.id,
          name: user.name,
          password: user.password,
          data: [...user.data, schedule],
          email: '',
          phone: '',
        );

        await _apiService.updateUser(updatedUser);
        await _hiveService.saveUser(updatedUser);

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
                  // Handle the selected date.
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите ваше имя',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: 'Введите номер телефона',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите номер телефона';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'Куда',
                  hintText: 'Введите место назначения',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите место назначения';
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
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Время',
                  hintText: 'Выберите время',
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, выберите время';
                  }
                  return null;
                },
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
