import 'package:ace_routes/controller/clockout/logout_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controller/clockout/clockout_controller.dart';
import '../controller/fontSizeController.dart';
import '../controller/loginController.dart';
import '../view/login_screen.dart';

Future<void> LogoutDailBox(BuildContext context) async {
  final fontSizeController = Get.find<FontSizeController>();
  // final loginController = Get.find<LoginController>();
  final ClockOut clockOut = Get.find<ClockOut>();
  final LogoutController logoutController = Get.put(LogoutController());
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
            onPressed: () async {
              final loginController = Get.find<LoginController>();
              // loginController.clearFields();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
              await clockOut.executeAction(tid: 10);
              print("logout tid 10");

              await logoutController.logout();
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
