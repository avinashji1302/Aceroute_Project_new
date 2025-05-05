import 'dart:async';
import 'dart:io';

import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/controller/connectivity/dependecy_injection.dart';
import 'package:ace_routes/controller/fontSizeController.dart';
import 'package:ace_routes/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

Future<void> logErrorToFile(String error, String stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/error_log.txt');
    final timestamp = DateTime.now().toIso8601String();
    final log = '[$timestamp] ERROR: $error\nSTACKTRACE:\n$stack\n\n';
    await file.writeAsString(log, mode: FileMode.append);
  } catch (e) {
    // Ignore logging errors
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up Flutter error logging
  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    await logErrorToFile(details.exception.toString(), details.stack.toString());
  };

  // Catch uncaught async errors
  runZonedGuarded(() {
    Get.put(FontSizeController());
    DependecyInjection.init();
    runApp(const MyApp());
  }, (error, stackTrace) async {
    await logErrorToFile(error.toString(), stackTrace.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
