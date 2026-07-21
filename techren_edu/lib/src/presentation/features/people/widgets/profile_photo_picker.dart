import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';

class ProfilePhotoPicker extends ConsumerStatefulWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.personId,
    required this.name,
    this.profileImage,
    this.isStudent = true,
    this.isActive = true,
    this.radius = 48,
    this.canEdit = true,
    this.onUpdated,
  });

  final String personId;
  final String name;
  final String? profileImage;
  final bool isStudent;
  final bool isActive;
  final double radius;
  final bool canEdit;
  final ValueChanged<String?>? onUpdated;

  @override
  ConsumerState<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends ConsumerState<ProfilePhotoPicker> {
  String? _profileImage;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _profileImage = widget.profileImage;
  }

  @override
  void didUpdateWidget(covariant ProfilePhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImage != widget.profileImage) {
      _profileImage = widget.profileImage;
    }
  }

  Future<void> _pickAndUpload() async {
    if (!widget.canEdit || _uploading) return;

    // Web has no filesystem path — must read bytes. Desktop/mobile can use path.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return;

    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && (path == null || path.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected image. Try another file.')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final api = ref.read(identityApiProvider);
      final Person updated;
      if (widget.isStudent) {
        updated = await api.uploadStudentPhoto(
          widget.personId,
          filePath: path,
          bytes: bytes,
          fileName: file.name,
        );
      } else {
        updated = await api.uploadTeacherPhoto(
          widget.personId,
          filePath: path,
          bytes: bytes,
          fileName: file.name,
        );
      }

      if (!mounted) return;
      setState(() => _profileImage = updated.profileImage);
      widget.onUpdated?.call(updated.profileImage);

      final currentUser = ref.read(authProvider).user;
      if (currentUser?.id == widget.personId) {
        ref.read(authProvider.notifier).updateProfileImage(updated.profileImage);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        PersonAvatar(
          name: widget.name,
          profileImage: _profileImage,
          radius: widget.radius,
          isActive: widget.isActive,
          isStudent: widget.isStudent,
        ),
        if (widget.canEdit)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _pickAndUpload,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: _uploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Icon(Icons.camera_alt, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
