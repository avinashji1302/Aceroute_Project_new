import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../database/Tables/event_table.dart';
import '../model/event_model.dart';

class SummaryController extends GetxController {
  RxString eventId = "".obs;
  RxString nm = "".obs;
  RxString startTime = "".obs;
  RxString category = "".obs;
  RxString duration = "".obs;

  // ✅ Raw DateTime strings for calculation
  RxString startDate = "".obs;
  RxString endDate = "".obs;

  // ✅ Formatted for UI display
  RxString displayStartDate = "".obs;

  final String id;
  SummaryController(this.id);

  @override
  void onInit() {
    super.onInit();
    fetchSummaryDetails();
  }

  Future<void> fetchSummaryDetails() async {
    Event? localEvent = await EventTable.fetchEventById(id);

    if (localEvent != null) {
      eventId.value = localEvent.id ?? '';
      nm.value = localEvent.nm ?? '';

      startDate.value = localEvent.start_date ?? '';
      endDate.value = localEvent.end_date ?? '';

      displayStartDate.value = formatEventDate(startDate.value);
      calculateDuration();
    }
  }

  // ✅ Converts raw string to formatted date and sets startTime
  String formatEventDate(String? date) {
    if (date == null || date.isEmpty) return "No Time";

    try {
      DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");
      DateTime dateTime = inputFormat.parse(date);

      String formattedDate = DateFormat("MMM dd yyyy").format(dateTime);
      String localTime = DateFormat.jm().format(dateTime.toLocal());

      startTime.value = localTime;
      return formattedDate;
    } catch (e) {
      print("❌ Error formatting date: $e");
      return "Invalid date";
    }
  }

  // ✅ Use raw dates to calculate duration
  void calculateDuration() {
    try {
      DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");

      DateTime start = inputFormat.parse(startDate.value);
      DateTime end = inputFormat.parse(endDate.value);

      Duration difference = end.difference(start);
      duration.value = "${difference.inMinutes} ";

      print("✅ Duration in minutes: ${duration.value}");
    } catch (e) {
      print("❌ Error calculating duration: $e");
    }
  }

  // ✅ Use this when selecting from date picker (sets raw and display together)
  void setPickedDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime withTime = DateTime(date.year, date.month, date.day, now.hour, now.minute);

    startDate.value = DateFormat("yyyy-MM-dd HH:mm:ss.SSS").format(withTime);
    displayStartDate.value = formatEventDate(startDate.value);
    calculateDuration();
  }
}
