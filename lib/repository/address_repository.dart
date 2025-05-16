import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final UserRepository _userRepository = UserRepository();

  Future<void> saveAddress(AddressModel address) async {
    await _firestore.collection('addresses').add(address.toJson());
  }

  Future<List<AddressModel>> getAddressesByUserId(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('addresses')
              .where('userId', isEqualTo: userId)
              .get();
      print("Địa chỉ của người dùng: $userId");
      return querySnapshot.docs
          .map((doc) => AddressModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print("Error getting addresses: $e");
      rethrow;
    }
  }

  Future<bool> updateAddress(String addressId, AddressModel newAddress) async {
    try {
      final addressQuery =
          await _firestore
              .collection('addresses')
              .where('addressId', isEqualTo: addressId)
              .get();

      if (addressQuery.docs.isEmpty) {
        return false;
      }

      await _firestore
          .collection('addresses')
          .doc(addressQuery.docs.first.id)
          .update(newAddress.toJson());

      return true;
    } catch (e) {
      print("Error updating address: $e");
      rethrow;
    }
  }

  Future<void> updateDefaultAddress(String addressId, bool isDefault) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String userId = "";
      if (user == null) {
        userId = await _userRepository.getEffectiveUserId();
        print("Guest user");
      } else {
        print("User logged in");
        userId = user.uid;
      }

      final addressQuery =
          await _firestore
              .collection('addresses')
              .where('addressId', isEqualTo: addressId)
              .where('userId', isEqualTo: userId)
              .get();

      if (addressQuery.docs.isEmpty) {
        throw Exception("Address not found");
      }

      await _firestore
          .collection('addresses')
          .doc(addressQuery.docs.first.id)
          .update({'isDefault': isDefault});
    } catch (e) {
      print("Error updating default address: $e");
      throw e;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return false;
    }
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final List<dynamic> addresses = userData['addresses'] ?? [];

        bool addressFound = addresses.any(
          (address) =>
              Map<String, dynamic>.from(address)['addressId'] == addressId,
        );

        if (addressFound) {
          List<dynamic> updatedAddresses =
              addresses
                  .where(
                    (address) =>
                        Map<String, dynamic>.from(address)['addressId'] !=
                        addressId,
                  )
                  .toList();

          await _firestore.collection('users').doc(userDoc.id).update({
            'addresses': updatedAddresses,
          });

          return true;
        }
      }

      return false;
    } catch (e) {
      print("Error deleting address: $e");
      throw e;
    }
  }

  Future<bool> deleteUserAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return false;
    }

    try {
      final querySnapshot =
          await _firestore
              .collection('addresses')
              .where('addressId', isEqualTo: addressId)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      await _firestore
          .collection('addresses')
          .doc(querySnapshot.docs.first.id)
          .delete();

      return true;
    } catch (e) {
      print("Error deleting address: $e");
      throw e;
    }
  }
}
