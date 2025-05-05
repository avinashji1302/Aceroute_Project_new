import 'package:ace_routes/controller/clockout/logout_controller.dart';
import 'package:ace_routes/controller/event_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:location/location.dart';

import '../controller/clockout/clockout_controller.dart';
import '../controller/fontSizeController.dart';
import '../controller/loginController.dart';
import '../view/login_screen.dart';

Future<void> LogoutDailBox(BuildContext context) async {
  final fontSizeController = Get.find<FontSizeController>();
  // final loginController = Get.find<LoginController>();
  final ClockOut clockOut = Get.find<ClockOut>();
  final LogoutController logoutController = Get.put(LogoutController());

  Location location = new Location(); // cloked in and out

  void _handleLogout(BuildContext context) async {
    try {
      // Get current location
      final position = await location.getLocation();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Perform your custom logout logic (e.g., clockOut)
      await clockOut.executeAction(
        tid: 10,
        timestamp: timestamp,
        latitude: position.latitude!,
        longitude: position.longitude!,
      );
      print("logout tid 10");

      // Call the API logout
      await logoutController.logout(
        timestamp,
        position.latitude!.toString(),
        position.longitude!.toString(),
      );

      // Clean up state
      Get.delete<LoginController>();
      Get.delete<EventController>();

      // Navigate to Login screen
      Get.offAll(() => LoginScreen());
    } catch (e) {
      print("Error during logout: $e");
      // Optionally show a snackbar or dialog
    }
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Confirm Logout',
          style: TextStyle(fontSize: fontSizeController.fontSize),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: fontSizeController.fontSize),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeController.fontSize)),
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
          ElevatedButton(
            child: Text('Logout',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeController.fontSize)),
            onPressed: () {
              // loginController.clearFields();

              // Get.delete<LoginController>();
              // Get.delete<EventController>(); // if needed

              // Navigator.of(context).pushReplacement(
              //   MaterialPageRoute(builder: (context) => LoginScreen()),
              // );

              // final position = await location.getLocation();
              // await clockOut.executeAction(
              //     tid: 10,
              //     timestamp: DateTime.now().millisecondsSinceEpoch,
              //     latitude: position.latitude!,
              //     longitude: position.longitude!);
              // print("logout tid 10");

              // await logoutController.logout();
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      );
    },
  );
}
