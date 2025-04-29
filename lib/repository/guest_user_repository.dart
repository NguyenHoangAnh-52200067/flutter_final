import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GuestUserRepository {
  static const String _guestIdKey = 'guest_id';

  static Future<String> getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString(_guestIdKey);

    if (guestId == null) {
      guestId = const Uuid().v4();
      await prefs.setString(_guestIdKey, guestId);
    }

    return guestId;
  }

  static Future<void> clearGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestIdKey);
  }
}
