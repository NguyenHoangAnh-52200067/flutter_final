import 'package:ecomerce_app/services/address_api_service.dart';
import 'package:flutter/material.dart';

class AddressSearchField extends StatefulWidget {
  final Function(String) onAddressSelect;
  AddressSearchField({super.key, required this.onAddressSelect});
  @override
  AddressSearchFieldState createState() => AddressSearchFieldState();
}

class AddressSearchFieldState extends State<AddressSearchField> {
  final AddressApiService apiService = AddressApiService();
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _suggestions = [];

  void _onSearchChanged(String query) {
    apiService.debounceSearch(query, (suggestions) {
      setState(() {
        _suggestions = suggestions;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 53, 53, 53),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ của bạn',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                prefixIcon: Icon(Icons.location_on),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              height: 250,
              child: SingleChildScrollView(
                child: Column(
                  children:
                      _suggestions.map((suggestion) {
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () {
                            _controller.text = suggestion['description'];
                            // Add a print statement or use a callback to handle the selected value
                            print(
                              'Selected address: ${suggestion['description']}',
                            );
                            widget.onAddressSelect(suggestion['description']);
                            setState(() {
                              _suggestions = [];
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
