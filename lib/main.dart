import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/passenger_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/driver_screen.dart';
import 'services/hive_service.dart';
import 'models/user_model.dart';
import 'package:device_preview/device_preview.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//
//
//   await Hive.initFlutter();
//   Hive.registerAdapter(UserModelAdapter());
//   await Hive.openBox('userBox');
//
//   final hiveService = HiveService();
//   final user = await hiveService.getUser();
//
//   runApp(MyApp(initialRoute: user != null ? '/driver' : '/passenger'));
// }
//
// class MyApp extends StatelessWidget {
//   final String initialRoute;
//
//   const MyApp({Key? key, required this.initialRoute}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Taxi App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         fontFamily: 'Roboto', // Используем шрифт, который поддерживает кириллицу
//       ),
//       initialRoute: initialRoute,
//       routes: {
//         '/passenger': (context) => const PassengerScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/register': (context) => const RegisterScreen(),
//         '/driver': (context) => const DriverScreen(),
//       },
//     );
//   }
// }



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox('userBox');

  final hiveService = HiveService();
  final user = await hiveService.getUser();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(initialRoute: user != null ? '/driver' : '/passenger'), // Wrap your app
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: initialRoute,
      routes: {
        '/passenger': (context) => const PassengerScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/driver': (context) => const DriverScreen(),
      },
    );
  }
}
