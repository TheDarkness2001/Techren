import 'package:flutter/material.dart';
import '../utils/media_url.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.profileImage,
    this.radius = 24,
    this.isActive = true,
    this.isStudent = true,
  });

  final String name;
  final String? profileImage;
  final double radius;
  final bool isActive;
  final bool isStudent;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(profileImage);
    final fallbackColor = isActive ? Colors.green.shade700 : Colors.grey;

    return CircleAvatar(
      radius: radius,
      backgroundColor: isActive ? Colors.green.shade50 : Colors.grey.shade200,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Icon(
              isStudent ? Icons.school_outlined : Icons.person_outline,
              color: fallbackColor,
            )
          : null,
    );
  }
}
