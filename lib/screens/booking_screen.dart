import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const BookingScreen({Key? key, required this.schedule}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  final _hiveService = HiveService();
  int _selectedPassengers = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  int _getTotalPassengers() {
    final clients = widget.schedule['clients'] ?? [];
    return clients.fold(0, (sum, client) => sum + (client['passengers'] as int));
  }

  bool _isFullyBooked() {
    final totalPassengers = _getTotalPassengers();
    return totalPassengers >= 4;
  }

  int _getAvailableSeats() {
    final totalPassengers = _getTotalPassengers();
    return 4 - totalPassengers;
  }

  Future<void> _bookSeat() async {
    if (_formKey.currentState!.validate()) {
      if (_isFullyBooked()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Все места уже забронированы')),
        );
        return;
      }

      if (_selectedPassengers > _getAvailableSeats()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Доступно только ${_getAvailableSeats()} мест')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final currentClients = widget.schedule['clients'] ?? [];
        final newClient = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'passengers': _selectedPassengers,
          'comment': _commentController.text,
        };

        currentClients.add(newClient);
        final updatedSchedule = Map<String, dynamic>.from(widget.schedule);
        updatedSchedule['clients'] = currentClients;

        await _apiService.updateSchedule(
          widget.schedule['driverId'],
          widget.schedule['id'],
          updatedSchedule,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Место успешно забронировано')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при бронировании места')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableSeats = _getAvailableSeats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование места'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Водитель: ${widget.schedule['driverName']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Телефон водителя: ${widget.schedule['driverPhone']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Время: ${widget.schedule['time']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Маршрут: ${widget.schedule['locationA']} - ${widget.schedule['locationB']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Доступно мест: $availableSeats',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  hintText: 'Введите ваше имя',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ваше имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Ваш телефон',
                  hintText: 'Введите ваш телефон',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите ваш телефон';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedPassengers,
                decoration: const InputDecoration(
                  labelText: 'Количество пассажиров',
                ),
                items: List.generate(
                  availableSeats,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} ${index + 1 == 1 ? 'пассажир' : 'пассажира'}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPassengers = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  hintText: 'Введите комментарий',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _bookSeat,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Забронировать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 