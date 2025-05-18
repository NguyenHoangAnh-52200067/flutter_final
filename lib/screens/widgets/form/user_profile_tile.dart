import 'package:ecommerce_app/screens/profile/edit_profile_screen.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
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
        backgroundColor: Colors.blue, // Nền xanh cho avatar
        child: ClipOval(
          child: ImageUtils.buildImage(linkImage, width: 55, height: 55),
        ),
      ),
      title: Text(
        fullName,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 16,
          color: Colors.white, // Tiêu đề màu xanh
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        email,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 12,
          color: Colors.white, // Phụ đề màu xanh đậm
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.edit,
          color: Colors.white,
        ), // Biểu tượng màu xanh
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
