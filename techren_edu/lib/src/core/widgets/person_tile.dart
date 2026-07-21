import 'package:flutter/material.dart';
import '../../domain/entities/person.dart';
import 'person_avatar.dart';

class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.person,
    this.onTap,
    this.trailing,
  });

  final Person person;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = person.isStudent
        ? person.email ?? person.displayId
        : '${person.role ?? 'staff'} · ${person.email ?? ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: PersonAvatar(
          name: person.name,
          profileImage: person.profileImage,
          isActive: person.isActive,
          isStudent: person.isStudent,
        ),
        title: Text(person.name),
        subtitle: Text(subtitle ?? ''),
        trailing: trailing ??
            Chip(
              label: Text(person.isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 12)),
              backgroundColor: person.isActive ? Colors.green.shade50 : Colors.red.shade50,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
      ),
    );
  }
}
