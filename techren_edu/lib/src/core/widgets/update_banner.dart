import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../update/app_updater.dart';

/// Shown on dashboards when the server has a newer native build.
/// On Windows the Update button downloads and installs the new version
/// automatically; on Android it downloads the APK for a one-tap install.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  bool _updating = false;
  double _progress = 0;

  Future<void> _update(AppUpdateInfo update) async {
    setState(() {
      _updating = true;
      _progress = 0;
    });
    try {
      await startPlatformUpdate(
        update,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      // On Windows the process exits before reaching here.
      if (mounted) setState(() => _updating = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Automatic update failed — opening the download page instead.')),
      );
      await launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(appUpdateProvider).valueOrNull;
    if (update == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update_alt_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _updating
                      ? 'Downloading update ${update.latestVersion}…'
                      : 'New version ${update.latestVersion} is available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _updating ? null : () => _update(update),
                icon: _updating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_updating ? 'Updating…' : 'Update'),
              ),
            ],
          ),
          if (_updating) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            ),
          ],
        ],
      ),
    );
  }
}
