import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/controller/clockout/clockout_controller.dart';
import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/controller/eform_controller.dart';
import 'package:ace_routes/controller/getOrderPart_controller.dart';
import 'package:ace_routes/controller/priority_controller.dart';
import 'package:ace_routes/database/Tables/OrderTypeDataTable.dart';
import 'package:ace_routes/database/Tables/api_data_table.dart';
import 'package:ace_routes/database/Tables/event_table.dart';
import 'package:ace_routes/database/Tables/prority_table.dart';
import 'package:ace_routes/model/login_model/token_api_response.dart';
import 'package:ace_routes/utils/TimeZoneUtils.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart' as xml;

import '../core/Constants.dart';
import '../core/colors/Constants.dart';
import '../database/Tables/status_table.dart';
import '../database/databse_helper.dart';
import '../model/event_model.dart';
import 'all_terms_controller.dart';
import 'orderNoteConroller.dart';

class EventController extends GetxController {
  // Controllers
  final allTermsController = Get.put(AllTermsController());
  final getOrderPart = Get.put(GetOrderPartController());
  final orderNoteController = Get.put(OrderNoteController());
  final eForm = Get.put(EFormController());
  final priority = Get.put(PriorityController());
  final clockOut = Get.put(ClockOut());
  final networkController = Get.find<NetworkController>();

  // Observables
  var events = <Event>[].obs;
  var isLoading = false.obs;
  var currentStatus = "Loading...".obs;

  var nameMap = <String, String?>{}.obs;
  var categoryMap = <String, String?>{}.obs;
  var priorityId = <String, String?>{}.obs;
  var priorityColorsId = <String, String?>{}.obs;

  // Config
  int daysToAdd = 1;
  DateTime? selectedDate;
  final Location location = Location();

  @override
  void onInit() async {
    super.onInit();
    isLoading(true);
    try {
      await loadAllTerms();
      await fetchEvents();
      await _fetchAndSyncNotes();
      await _logInitialLocation();
      await _startBackgroundService();
      networkController.enableSyncAfterLogin();
    } catch (e) {
      print("❌ Error in onInit: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> _fetchAndSyncNotes() async {
    try {
      await orderNoteController.fetchDetailsFromDb();
      await orderNoteController.fetchOrderNotesFromApi();
    } catch (e) {
      print("❌ Error syncing order notes: $e");
    }
  }

  Future<void> _logInitialLocation() async {
    try {
      final position = await location.getLocation();
      print(
          "📍 Initial login location: ${position.latitude}, ${position.longitude}");
      await clockOut.executeAction(
        tid: 11,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        latitude: position.latitude!,
        longitude: position.longitude!,
      );
    } catch (e) {
      print("❌ Error logging initial location: $e");
    }
  }

  Future<void> _startBackgroundService() async {
    try {
      List<TokenApiReponse> loginDataList = await ApiDataTable.fetchData();
      String gpsMin =
          loginDataList.isNotEmpty ? loginDataList.first.gpsSync : "10";
      String gpsMeter =
          loginDataList.isNotEmpty ? loginDataList.first.locationChange : "500";

      List<Event> localEvents = await EventTable.fetchEvents();
      Set<String> wkfSet = localEvents.map((e) => e.wkf.toString()).toSet();

      Map<String, String?> fetchedStatus =
          await StatusTable.fetchNamesByIds(wkfSet.toList());

      List<String> validOrderIds = localEvents
          .where((e) => fetchedStatus[e.wkf] != "Complete")
          .map((e) => e.id.toString())
          .take(2)
          .toList();

      String lstoid = validOrderIds.isNotEmpty ? validOrderIds[0] : "0";
      String nxtoid = validOrderIds.length > 1 ? validOrderIds[1] : "0";

      print("📦 lstoid: $lstoid, nxtoid: $nxtoid");

      Get.put(GeoServiceController(
        gpsSyncMins: gpsMin,
        locChangeMeters: gpsMeter,
        token: token,
        nspace: nsp,
        rid: rid,
        lstoid: lstoid,
        nxtoid: nxtoid,
      ));
    } catch (e) {
      print("❌ Error in background service: $e");
    }
  }

  Future<void> loadAllTerms() async {
    try {
      Database db = await DatabaseHelper().database;
      await allTermsController.fetchStatusList();
      await allTermsController.fetchAndStoreOrderTypes();
      await allTermsController.displayLoginResponseData();
      await allTermsController.GetAllPartTypes();
      await allTermsController.fetchAndStoreGTypes(db);
      await allTermsController.GetAllTerms();
      await AllTerms.getTerm();
      await priority.getPriorityData();
    } catch (e) {
      print("❌ Error loading all terms: $e");
    }
  }

  Future<void> fetchEvents() async {
    try {
      isLoading(true);

      // Use local dates
      DateTime currentDate = selectedDate ?? DateTime.now();
      DateTime secondDate = currentDate.add(Duration(days: daysToAdd));

      // Format dates in yyyy-MM-dd using local time
      String fromDate = DateFormat('yyyy-MM-dd').format(currentDate);
      String toDate = DateFormat('yyyy-MM-dd').format(secondDate);

      // Get timezone offset in minutes (e.g., +330 for IST, -420 for PDT)
      int tzOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;

      // Compose URL
      String url =
          "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid"
          "&action=getorders&tz=$tzOffsetMinutes&from=$fromDate&to=$toDate";

      print("🌐 Fetching events: $url");
      print(
          "📍 Device TimeZone: ${DateTime.now().timeZoneName}, Offset: $tzOffsetMinutes mins");

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        parseXmlResponse(response.body);
        await loadEventsFromDatabase();
      } else {
        print("❌ Failed to fetch events: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching events: $e");
    } finally {
      isLoading(false);
    }
  }

  void parseXmlResponse(String xmlString) {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final eventElements = document.findAllElements('event');

      List<Event> fetchedEvents = eventElements.map((element) {
        final rawStartDate = _getText(element, 'start_date');
        final rawEndDate = _getText(element, 'end_date');

        final localStart = TimeZoneUtils.parseUtcToLocal(rawStartDate);
        final localEnd = TimeZoneUtils.parseUtcToLocal(rawEndDate);

        print("start $localStart end $localEnd");

        return Event(
          id: _getText(element, 'id'),
          cid: _getText(element, 'cid'),
          start_date: localStart.toString(), // Local time
          etm: _getText(element, 'etm'),
          end_date: localEnd.toString(), // Local time
          nm: _getText(element, 'nm'),
          wkf: _getText(element, 'wkf'),
          alt: _getText(element, 'alt'),
          po: _getText(element, 'po'),
          inv: _getText(element, 'inv'),
          tid: _getText(element, 'tid'),
          pid: _getText(element, 'pid'),
          rid: _getText(element, 'rid'),
          ridcmt: _getText(element, 'ridcmt'),
          dtl: _getText(element, 'dtl'),
          lid: _getText(element, 'lid'),
          cntid: _getText(element, 'cntid'),
          flg: _getText(element, 'flg'),
          est: _getText(element, 'est'),
          lst: _getText(element, 'lst'),
          ctid: _getText(element, 'ctid'),
          ctpnm: _getText(element, 'ctpnm'),
          ltpnm: _getText(element, 'ltpnm'),
          cnm: _getText(element, 'cnm'),
          address: _getText(element, 'adr'),
          geo: _getText(element, 'geo'),
          cntnm: _getText(element, 'cntnm'),
          tel: _getText(element, 'tel'),
          ordfld1: _getText(element, 'ordfld1'),
          ttid: _getText(element, 'ttid'),
          cfrm: _getText(element, 'cfrm'),
          cprt: _getText(element, 'cprt'),
          xid: _getText(element, 'xid'),
          cxid: _getText(element, 'cxid'),
          tz: _getText(element, 'tz'),
          zip: _getText(element, 'zip'),
          fmeta: _getText(element, 'fmeta'),
          cimg: _getText(element, 'cimg'),
          caud: _getText(element, 'caud'),
          csig: _getText(element, 'csig'),
          cdoc: _getText(element, 'cdoc'),
          cnot: _getText(element, 'cnot'),
          dur: _getText(element, 'dur'),
          val: _getText(element, 'val'),
          rgn: _getText(element, 'rgn'),
          upd: _getText(element, 'upd'),
          by: _getText(element, 'by'),
          znid: _getText(element, 'znid'),
        );
      }).toList();

      for (final event in fetchedEvents) {
        EventTable.insertEvent(event);
      }

      events.assignAll(fetchedEvents);
    } catch (e) {
      print("❌ Error parsing XML: $e");
    }
  }

// Helper to extract text from XML element
  String _getText(xml.XmlElement element, String tag) {
    return element.getElement(tag)?.text ?? '';
  }

  Future<void> loadEventsFromDatabase() async {
    try {
      isLoading(true);

      List<Event> localEvents = await EventTable.fetchEvents();
      events.assignAll(localEvents);

      // Unique IDs
      Set<String> wkfSet = localEvents.map((e) => e.wkf).toSet();
      Set<String> tidSet = localEvents.map((e) => e.tid).toSet();
      Set<String> pidSet = localEvents.map((e) => e.pid).toSet();

      nameMap.value = await StatusTable.fetchNamesByIds(wkfSet.toList());
      categoryMap.value =
          await OrderTypeDataTable.fetchCategoriesByIds(tidSet.toList());
      priorityId.value =
          await PriorityTable.fetchPrioritiesByIds(pidSet.toList());
      priorityColorsId.value =
          await PriorityTable.fetchPrioritiesColorsByIds(pidSet.toList());
    } catch (e) {
      print("❌ Error loading events from DB: $e");
    } finally {
      isLoading(false);
    }
  }

  // String _getText(xml.XmlElement element, String tagName) {
  //   return element.findElements(tagName).isNotEmpty
  //       ? element.findElements(tagName).single.text
  //       : '';
  // }
}
