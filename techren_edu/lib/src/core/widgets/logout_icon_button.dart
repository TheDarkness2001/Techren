import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/auth_provider.dart';

/// Accessible logout action used in scaffold app bars (Phase F.6).
class LogoutIconButton extends ConsumerWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Log out',
      onPressed: () => ref.read(authProvider.notifier).logout(),
      icon: const Icon(Icons.logout),
    );
  }
}
