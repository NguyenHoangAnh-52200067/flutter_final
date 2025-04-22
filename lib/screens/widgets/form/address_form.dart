import 'package:ecomerce_app/screens/widgets/button_input/dropdown_field.dart';
import 'package:ecomerce_app/screens/widgets/button_input/input_field.dart';
import 'package:ecomerce_app/services/address_service.dart';
import 'package:flutter/material.dart';

class AddressForm extends StatefulWidget {
  final Function(String) onAddressChanged;
  const AddressForm({super.key, required this.onAddressChanged});

  @override
  _AddressFormState createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? selectedDistrict;
  String? selectedWard;
  String? selectedCity;

  List<String> districts = [];
  List<String> wards = [];
  String? lastSearchedStreet;

  Future<void> fetchDistricts() async {
    String streetName = _streetController.text.trim();

    if (streetName.isEmpty || streetName == lastSearchedStreet) return;
    lastSearchedStreet = streetName;

    try {
      List<Map<String, String>> results = await AddressService.searchStreet(
        streetName,
      );
      print("Dữ liệu từ API: $results");

      if (results.isNotEmpty) {
        Set<String> uniqueDistricts =
            results.map((e) => e["district"] ?? "").toSet();
        setState(() {
          districts =
              uniqueDistricts.where((e) => e.isNotEmpty).toList()..sort();
          selectedDistrict = null;
          selectedWard = null;
          wards.clear();
        });
      } else {
        setState(() {
          districts.clear();
          selectedDistrict = null;
          wards.clear();
          selectedWard = null;
          _cityController.clear();
        });
      }
    } catch (e) {
      print("Lỗi khi fetch quận: $e");
    }
  }

  Future<void> fetchWards() async {
    if (selectedDistrict == null) return;

    try {
      List<Map<String, String>> results = await AddressService.searchStreet(
        _streetController.text,
      );

      Set<String> uniqueWards =
          results
              .where((e) => e["district"] == selectedDistrict)
              .map((e) => e["ward"] ?? "")
              .toSet();

      String? city =
          results.firstWhere(
            (e) => e["district"] == selectedDistrict,
            orElse: () => {"city": ""},
          )["city"];

      setState(() {
        wards = uniqueWards.where((e) => e.isNotEmpty).toList()..sort();
        selectedWard = null;
        selectedCity = city;
        _cityController.text = city ?? "";
        _updateAddress();
      });
    } catch (e) {
      print("Lỗi khi fetch phường: $e");
    }
  }

  void _updateAddress() {
    String street = _streetController.text.trim();
    if (street.isEmpty ||
        selectedDistrict == null ||
        selectedWard == null ||
        selectedCity == null) {
      return;
    }

    String fullAddress =
        "$street, $selectedDistrict, $selectedWard, $selectedCity";
    widget.onAddressChanged(fullAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputField(
          controller: _streetController,
          hintText: "Số nhà + Tên đường",
          icon: Icons.location_on,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.text,
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              fetchDistricts();
              _updateAddress();
            },
          ),
        ),
        DropdownField(
          hintText: "Chọn Quận",
          value: selectedDistrict,
          items: districts,
          icon: Icons.apartment,
          onChanged: (value) {
            if (selectedDistrict != value) {
              setState(() {
                selectedDistrict = value;
                selectedWard = null;
                fetchWards();
                _updateAddress();
              });
            }
          },
        ),
        DropdownField(
          hintText: "Chọn Phường",
          value: selectedWard,
          items: wards,
          icon: Icons.location_city,
          onChanged: (value) {
            setState(() {
              selectedWard = value;
              _updateAddress();

            });
          },
        ),
        InputField(
          controller: _cityController,
          hintText: "Thành phố",
          icon: Icons.map,
          readOnly: true,
        ),
      ],
    );
  }
}
