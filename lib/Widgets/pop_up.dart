import 'package:ace_routes/controller/loginController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

Future<bool> onWillPop(BuildContext context) async {

  final logincontroller = Get.find<LoginController>();
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () {
            
              Get.delete();
              Navigator.of(context).pop(false);
            }, // Stay on page
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Exit page
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false; // In case dialog dismissed without selection
  }