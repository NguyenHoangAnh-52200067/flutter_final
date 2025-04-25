import 'package:ecomerce_app/screens/profile/edit_profile_screen.dart';
import 'package:ecomerce_app/utils/image_utils.dart';
import 'package:flutter/material.dart';

class UserProfileTile extends StatelessWidget {
  final String? linkImage;
  final String fullName;
  final String email;

  const UserProfileTile({
    super.key,
    required this.fullName,
    required this.email,
    this.linkImage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: ImageUtils.buildImage(linkImage, width: 30, height: 30),
      ),
      title: Text(
        fullName,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        email,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProfileScreen()),
          );
        },
      ),
    );
  }
}
