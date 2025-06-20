import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../database/Tables/event_table.dart'; // EventTable for DB operations
import '../model/event_model.dart';

class SummaryController extends GetxController {
  // Collecting summary data
  RxString eventId = "".obs;
  RxString nm = "".obs;
  RxString startTime = "".obs;
  RxString category = "".obs;
  RxString duration = "".obs;
  RxString startDate = "".obs;
  RxString endDate = "".obs;

  final String id; // Add an id parameter

  SummaryController(this.id); // Constructor to accept id

  @override
  void onInit() {
    super.onInit();
    fetchSummaryDetails();
    print("id is $id");
  }

  Future<void> fetchSummaryDetails() async {
    // This data is coming from event database
    Event? localEvent = await EventTable.fetchEventById(id);

    if (localEvent != null) {
      eventId.value = localEvent.id ?? '';
      nm.value = localEvent.nm ?? '';
      startDate.value = localEvent.start_date ?? '';
      endDate.value = localEvent.end_date ?? '';

      // Calculate the duration
      calculateDuration();
      startDate.value = formatEventDate(startDate.value);
    } else {
      print("No event found for the given ID");
    }
  }

  // Function to format the event date and time
  String formatEventDate(String? date) {
    if (date == null || date.isEmpty) {
      return "No Time";
    }
    try {
      print("Raw date: $date");

      DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");
      DateTime dateTime = inputFormat.parse(date);

      String formattedDate = DateFormat("MMMM dd yyyy").format(dateTime);
      String localTime = DateFormat.jm().format(dateTime.toLocal());

      startTime.value = localTime;
      print("Formatted date: $formattedDate, time: $localTime");

      return formattedDate;
    } catch (e) {
      print("❌ Error formatting date: $e");
      return "Invalid date";
    }
  }

  // Function to calculate the duration between start and end time
  void calculateDuration() {
    try {
      DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      DateTime start = inputFormat.parse(startDate.value);
      DateTime end = inputFormat.parse(endDate.value);

      Duration difference = end.difference(start);
      duration.value = "${difference.inMinutes} ";

      print("✅ Duration in minutes: ${duration.value}");
    } catch (e) {
      print("❌ Error calculating duration: $e");
    }
  }
}
