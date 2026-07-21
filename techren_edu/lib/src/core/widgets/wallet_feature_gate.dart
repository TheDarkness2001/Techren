import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../../presentation/providers/settings_provider.dart';
import 'common_widgets.dart';

class WalletFeatureGate extends ConsumerWidget {
  const WalletFeatureGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(walletEnabledProvider);
    if (enabled) return child;

    return const Center(
      child: Padding(
        padding: AppSpacing.pagePaddingWide,
        child: EmptyState(
          title: 'Wallet disabled',
          message: 'Student wallets are turned off. Enable the wallet feature in platform settings.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ),
    );
  }
}
