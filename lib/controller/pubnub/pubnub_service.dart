import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/controller/event_controller.dart';
import 'package:ace_routes/controller/orderNoteConroller.dart';
import 'package:ace_routes/controller/vehicle_controller.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/Tables/event_table.dart';
import 'package:ace_routes/utils/TimeZoneUtils.dart';
import 'package:ace_routes/view/login_screen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pubnub/pubnub.dart';
import 'package:xml/xml.dart';

class PubNubService extends GetxController {
  late final PubNub pubnub;
  late final Subscription subscription;
  final String userId;
  final String namespace;
  final String subscriptionKey;

  final eventController = Get.find<EventController>();
  final NetworkController networkController = Get.find<NetworkController>();

  PubNubService({
    required this.userId,
    required this.namespace,
    required this.subscriptionKey,
  }) {
    pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: subscriptionKey,
        userId: UserId('$namespace-$userId'),
      ),
    );
    _subscribeToChannel();
    print("✅ PubNub Initialized: userId = $userId, key = $subscriptionKey");
  }

  void _subscribeToChannel() {
    print("🔔 Subscribing to channel: $namespace");
    subscription = pubnub.subscribe(channels: {namespace});

    subscription.messages.listen((envelope) async {
      print("📩 New Message Received!");
      final payload = envelope.payload;

      print("📩 payload::: $payload");

      try {
        final timestamp = int.tryParse(payload['s']?.toString() ?? '0') ?? 0;
        final senderRid = payload['u']?.toString().trim().toLowerCase() ?? '';
        final xml = payload['x'] ?? '';
        final keyParts = (payload['k']?.toString() ?? '').split('|');

        if (keyParts.length < 3) {
          print("⚠️ Invalid key format: $keyParts  $xml");
          return;
        }

        final msgType = keyParts[0];
        final actionType = keyParts[1];
        final msgUserId = keyParts[2];

        const allowedMsgTypes = {
          '14',
          '5',
          '6',
          '9',
          '13',
          '24',
          '27',
          '54',
          '58',
          '59'
        };

        if (!allowedMsgTypes.contains(msgType)) {
          print("⚠️ Ignored: Unhandled msgType = $msgType");
          return;
        }

        final localUser = userId.trim().toLowerCase();
        if (senderRid == localUser ||
            senderRid == msgUserId.trim().toLowerCase()) {
          print("🙅 Ignored: Message from self ($senderRid)");
          return;
        }

        print("📤 Handling msgType = $msgType");

        switch (msgType) {
          case '14':
            if (actionType == '2') {
              print("🗑️ Deleting Order: $msgUserId");
              // Implement delete logic if needed
              EventTable().deleteEvent(msgUserId);
              Get.find<EventController>().loadEventsFromDatabase();
            }

            final ridFromXml = _extractXmlValue(xml, 'rid');
            if (ridFromXml != null && ridFromXml != rid) {
              print("📤 Ignored: Order RID mismatch ($ridFromXml != $rid)");
              return;
            }

            if (['0', '1', '3'].contains(actionType)) {
              await _handleOrderMessage(xml, actionType);
            }
            break;

          case '13':
            print("📝 Order Note Changed $xml");
            final orderNoteController = Get.find<OrderNoteController>();
            final vehicleController = Get.put(VehicleController(msgUserId));

            await orderNoteController.fetchOrderNotesFromApi();
            vehicleController.GetVehicleDetails();

            break;

          case '58':
            print("🔄 Forced Logout");

            // EventTable.clearEvents();
            Get.deleteAll();
            Get.to(() => const LoginScreen());
            break;

          case '54':
            print("🔄 Revoked");
            Get.deleteAll();
            Get.to(() => const LoginScreen());
            break;

          case '59':
            print("🔄 sync");
            // Enable sync flag in case it was disabled
            networkController.canSync = true;

            // Then call the sync methods
            Get.find<NetworkController>().syncAll();
            print("🔁 Manual sync triggered");

            break;

          case '6':
            print("🔄 Part type");
            break;

          default:
            print("⚠️ Unknown msgType: $msgType");
        }

        print(
            "✅ Message handled at $timestamp from $senderRid with key $keyParts");
      } catch (e) {
        print("❌ Error while handling message: $e");
      }
    });
  }

  Future<void> _handleOrderMessage(String xml, String actionType) async {
    print("📦 Handling Order Message [actionType = $actionType]");
    print("🧾 XML:\n$xml");

    final orderId = _extractXmlValue(xml, 'id') ?? '';
    final rid = _extractXmlValue(xml, 'rid') ?? '';
    print("🔍 Parsed Order -> ID: $orderId, RID: $rid");

    switch (actionType) {
      case '0':
        print("🛠️ Updating order...");
        // TODO: Add update logic
        break;

      case '1':
        print("➕ Adding new order...");
        XmlDocument.parse(xml); // Validate XML
        EventController().parseXmlResponse(xml);
        Get.find<EventController>().loadEventsFromDatabase();
        break;

      case '3':
        print("♻️ Partially updating order...");
        final doc = XmlDocument.parse(xml);
        final eventElement = doc.findElements('event').firstOrNull;

        if (eventElement == null) {
          print("❌ Missing <event> element in XML.");
          return;
        }

        final eventId = eventElement.getElement('id')?.text ?? '';
        if (eventId.isEmpty) {
          print("❌ Event ID missing in XML. Cannot update.");
          return;
        }

        final Map<String, dynamic> updatedFields = {};
        final fieldTags = [
          'cid',
          'start_date',
          'etm',
          'end_date',
          'nm',
          'wkf',
          'alt',
          'po',
          'inv',
          'tid',
          'pid',
          'rid',
          'ridcmt',
          'dtl',
          'lid',
          'cntid',
          'flg',
          'est',
          'lst',
          'ctid',
          'ctpnm',
          'ltpnm',
          'cnm',
          'address',
          'geo',
          'cntnm',
          'tel',
          'ordfld1',
          'ttid',
          'cfrm',
          'cprt',
          'xid',
          'cxid',
          'tz',
          'zip',
          'fmeta',
          'cimg',
          'caud',
          'csig',
          'cdoc',
          'cnot',
          'dur',
          'val',
          'rgn',
          'upd',
          'by',
          'znid'
        ];

        for (final tag in fieldTags) {
          final value = eventElement.getElement(tag)?.text;
          if (value != null) {
            String trimmedValue = value.trim();

            // Convert start_date and end_date to local time
            if (tag == 'start_date' || tag == 'end_date') {
              trimmedValue = TimeZoneUtils.formatUtcToLocal(trimmedValue);
            }

            updatedFields[tag] = trimmedValue;
          }
        }

        await EventTable.patchEventFields(eventId, updatedFields);
        Get.find<EventController>().loadEventsFromDatabase();
        print("✅ Event $eventId patched: $updatedFields");
        break;

      default:
        print("⚠️ Unknown ActionType = $actionType");
    }
  }

 

  String? _extractXmlValue(String xml, String tag) {
    final regex = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim();
  }
}
