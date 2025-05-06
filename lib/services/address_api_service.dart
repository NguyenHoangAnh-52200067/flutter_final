import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AddressApiService {
  final String baseUrl = 'rsapi.goong.io';
  final String baseUrl_ = 'https://rsapi.goong.io/Place';

  final String apiKey = 'KeONrT42qDbhvyFK5oLjywhE0EAcrxeHh0NTznDz';
  final String sessionToken = Uuid().v4(); // token mỗi lần request
  Timer? _debounce;

  void debounceSearch(String query, Function(List<dynamic>) onResult) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () async {
      if (query.length < 2) {
        onResult([]);
        return;
      }
      List<dynamic> suggestions = await fetchAddressSuggestions(query);
      onResult(suggestions);
    });
  }

  Future<List<dynamic>> fetchAddressSuggestions(String query) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl_/AutoComplete?api_key=$apiKey&input=${Uri.encodeComponent(query)}&sessiontoken=$sessionToken',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return data['predictions'];
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchAddressDetails(String placeId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl_/Detail?place_id=$placeId&api_key=$apiKey&sessiontoken=$sessionToken',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' &&
          data['result'] != null &&
          data['result']['geometry'] != null) {
        return {
          'lat': data['result']['geometry']['location']['lat'],
          'lng': data['result']['geometry']['location']['lng'],
          'province': data['result']['compound']?['province'] ?? '',
          'district': data['result']['compound']?['district'] ?? '',
          'ward': data['result']['compound']?['commune'] ?? '',
        };
      }
    }
    return null;
  }

  void deplayedSearchReq(String? query, Function(List<String>) onResult) {
    if (_debounce != null && _debounce!.isActive) {
      _debounce!.cancel();
    }

    _debounce = Timer(Duration(milliseconds: 300), () async {
      if (query == null || query.length < 2) {
        onResult([]);
        return;
      }

      List<String> addresses = await fetchAddress(query);
      onResult(addresses);
    });
  }

  Future<List<String>> fetchAddress(String query) async {
    final Uri url = Uri.https(baseUrl, 'Place/AutoComplete', {
      'api_key': apiKey,
      'input': query,
      'sessiontoken': sessionToken,
    });
    print("URL fetch address url : $url");
    final response = await http.get(url);
    print("Response goong api: $response");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("DATA NE:\n $data");

      List<String> addresses =
          (data['predictions'] as List)
              .map((item) => item['description'].toString())
              .toList();

      return addresses;
    }
    return [];
  }
}
