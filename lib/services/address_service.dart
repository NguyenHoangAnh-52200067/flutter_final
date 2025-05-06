import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  static Future<List<Map<String, String>>> searchStreet(String streetName) async {
    final url =
        "https://nominatim.openstreetmap.org/search?format=json&q=$streetName, Vietnam";
    print("Gửi request đến API: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("Phản hồi API: ${response.statusCode}");

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        List<Map<String, String>> addresses = [];

        for (var place in data) {
          String displayName = place['display_name'];
          List<String> parts = displayName.split(", ").reversed.toList();

          String? street, ward, district, city;

          city = parts.firstWhere(
              (p) => p.contains("Thành phố") || p.contains("Hồ Chí Minh") || p.contains("Hà Nội"),
              orElse: () => "");

          district = parts.firstWhere(
              (p) => p.contains("Quận") || p.contains("Huyện") || p.contains("District"),
              orElse: () => "");

          ward = parts.firstWhere(
              (p) => p.contains("Phường") || p.contains("Xã") || p.contains("Ward"),
              orElse: () => "");

          street = parts.lastWhere(
              (p) => p != city && p != district && p != ward,
              orElse: () => "");

          if (street.isNotEmpty && ward.isNotEmpty && district.isNotEmpty && city.isNotEmpty) {
            addresses.add({
              "street": street,
              "ward": ward,
              "district": district,
              "city": city,
            });
          } else {
            print("abc: $displayName");
          }
        }

        print("Danh sách địa chỉ lấy được: $addresses");
        return addresses;
      }
      print("Lỗi API: ${response.statusCode} - ${response.body}");
    } catch (e) {
      print("Lỗi khi gọi API: $e");
    }

    return [];
  }
}
