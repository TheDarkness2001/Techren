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

    final statusChip = Chip(
      label: Text(person.isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 12)),
      backgroundColor: person.isActive ? Colors.green.shade50 : Colors.red.shade50,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackActions = trailing != null && constraints.maxWidth < 420;
          final tile = ListTile(
            onTap: onTap,
            leading: PersonAvatar(
              name: person.name,
              profileImage: person.profileImage,
              isActive: person.isActive,
              isStudent: person.isStudent,
            ),
            title: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(subtitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: stackActions ? statusChip : (trailing ?? statusChip),
          );
          if (!stackActions) return tile;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile,
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
