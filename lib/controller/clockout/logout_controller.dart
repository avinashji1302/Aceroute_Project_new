import 'package:ace_routes/core/colors/Constants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LogoutController extends GetxController{
  final String url =
      "https://portal.aceroute.com/mobi?token=$token&nspace=$nsp&geo=<current lat,lon>&rid=$rid&action=logout&stmp=<timestamp>";

  Future<void> logout() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("Logout successful: ${response.body}");
    } else {
      print("Logout failed: ${response.statusCode} - ${response.body}");
    }
  }
}
