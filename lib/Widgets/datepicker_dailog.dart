import 'package:ace_routes/controller/event_controller.dart';
import 'package:ace_routes/database/Tables/event_table.dart';
import 'package:ace_routes/view/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controller/fontSizeController.dart';
import '../controller/homeController.dart';

void showDatePickerDialog(BuildContext context) {
  final fontSizeController = Get.find<FontSizeController>();
  final homeController =
      Get.find<HomeController>(); // Assuming you're using GetX
  final eventController = Get.find<EventController>();
  DateTime? _tempSelectedDate; // temporary storage within dialog

  showDialog(
    
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (selectedDate) {
                // Store the selected date in the controller
                _tempSelectedDate = selectedDate;
                homeController.setSelectedDate(selectedDate);
              },
            ),
            Divider(
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel..',
                    style: TextStyle(fontSize: fontSizeController.fontSize),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_tempSelectedDate != null) {
                      eventController.selectedDate = _tempSelectedDate;
                      print("_tempSelectedDate");
                      print(_tempSelectedDate);
                      EventTable.clearEvents(); // clear previous events
                      eventController.fetchEvents(); // fetch for selected date
                    }
                    Navigator.pop(context);

                    Get.to(() => HomeScreen());
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: fontSizeController.fontSize),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
