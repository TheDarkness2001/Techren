import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../update/app_updater.dart';

/// Shown on dashboards when a newer native build is published.
/// Tap Update → download inside the app → install over the current app (no uninstall,
/// no Downloads folder). Android shows one system "Update" confirmation (required by OS).
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  bool _updating = false;
  double _progress = 0;
  String _phase = '';

  Future<void> _update(AppUpdateInfo update) async {
    setState(() {
      _updating = true;
      _progress = 0;
      _phase = 'Downloading update ${update.latestVersion}…';
    });
    try {
      await startPlatformUpdate(
        update,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            if (p >= 0.99) {
              _phase = 'Installing… confirm Update on the next screen';
            } else {
              _phase = 'Downloading update ${update.latestVersion}…';
            }
          });
        },
      );
      if (mounted) {
        setState(() {
          _updating = false;
          _phase = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _updating = false;
        _phase = '';
      });
      final needsPermission = e.toString().contains('Allow installs');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            needsPermission
                ? 'Allow installs from TechRen EDU in Settings, then tap Update again.'
                : 'Update failed. Tap Update to retry — installs inside the app (no Downloads folder).',
          ),
          action: needsPermission
              ? null
              : SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _update(update),
                ),
        ),
      );
    }
  }

  Future<void> _manualDownload(AppUpdateInfo update) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual download?'),
        content: const Text(
          'Normally Update installs inside the app. Only use this if in-app install keeps failing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open link')),
        ],
      ),
    );
    if (ok == true) {
      await launchUrl(update.platformInstallerUrl, mode: LaunchMode.externalApplication);
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
                      ? (_phase.isEmpty ? 'Updating…' : _phase)
                      : 'New version ${update.latestVersion} is available — installs over this app',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _updating ? null : () => _update(update),
                onLongPress: _updating ? null : () => _manualDownload(update),
                icon: _updating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.system_update_alt_rounded, size: 18),
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
