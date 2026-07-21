import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/upload.dart';
import '../../../providers/upload_provider.dart';

class ContentImportScreen extends ConsumerStatefulWidget {
  const ContentImportScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<ContentImportScreen> createState() => _ContentImportScreenState();
}

class _ContentImportScreenState extends ConsumerState<ContentImportScreen> {
  String _contentType = 'words';
  String? _lessonId;
  List<ImportPair> _pairs = [];
  String? _statusMessage;
  bool _busy = false;
  bool _ocrEnabled = true;
  String? _ocrImageUrl;
  final _pasteController = TextEditingController();

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  List<ImportPair> _parsePairsFromText(String text) {
    final pairs = <ImportPair>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final match = RegExp(r'^(.+?)\s*[-–—:]\s*(.+)$').firstMatch(trimmed);
      if (match != null) {
        pairs.add(ImportPair(english: match.group(1)!.trim(), uzbek: match.group(2)!.trim()));
      }
    }
    return pairs;
  }

  void _setParsedPairs(ParseImportResult parsed, {String? fallbackMessage}) {
    setState(() {
      _pairs = parsed.pairs;
      _ocrEnabled = parsed.ocrEnabled;
      _ocrImageUrl = parsed.imageUrl;
      if (parsed.pairs.isNotEmpty) {
        _statusMessage = 'Parsed ${parsed.pairCount} pair(s)${parsed.source != null ? ' from ${parsed.source}' : ''}';
      } else {
        _statusMessage = parsed.message ?? fallbackMessage ?? 'No pairs found';
      }
    });
  }

  Future<void> _pickAndParseDocx() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx', 'txt'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.path == null && file.bytes == null) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
    });

    try {
      final parsed = await ref.read(uploadApiProvider).parseDocx(
            filePath: file.path,
            bytes: file.bytes,
            fileName: file.name,
          );
      _setParsedPairs(parsed);
    } catch (e) {
      setState(() => _statusMessage = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndParseOcr() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.path == null && file.bytes == null) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
      _ocrImageUrl = null;
    });

    try {
      final parsed = await ref.read(uploadApiProvider).parseOcr(
            filePath: file.path,
            bytes: file.bytes,
            fileName: file.name,
          );
      _setParsedPairs(parsed);
    } catch (e) {
      setState(() => _statusMessage = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  void _parsePastedPairs() {
    final pairs = _parsePairsFromText(_pasteController.text);
    setState(() {
      _pairs = pairs;
      _ocrEnabled = true;
      _ocrImageUrl = null;
      _statusMessage = pairs.isEmpty
          ? 'No valid lines found. Use format: english - uzbek'
          : 'Parsed ${pairs.length} pair(s) from pasted text';
    });
  }

  Future<void> _importPairs() async {
    if (_lessonId == null || _pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a lesson and parse a file first')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final api = ref.read(uploadApiProvider);
      final result = _contentType == 'words'
          ? await api.bulkImportWords(lessonId: _lessonId!, pairs: _pairs)
          : await api.bulkImportSentences(lessonId: _lessonId!, pairs: _pairs);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${result.created}, skipped ${result.skipped}')),
      );
      setState(() => _statusMessage = 'Imported ${result.created}, skipped ${result.skipped}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadMedia({required bool audio}) async {
    final result = await FilePicker.platform.pickFiles(
      type: audio ? FileType.audio : FileType.image,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.path == null && file.bytes == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(uploadApiProvider);
      final uploaded = audio
          ? await api.uploadAudio(filePath: file.path, bytes: file.bytes, fileName: file.name)
          : await api.uploadImage(filePath: file.path, bytes: file.bytes, fileName: file.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded: ${uploaded.url}')));
      setState(() => _statusMessage = 'Uploaded ${uploaded.url}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = _contentType == 'words'
        ? ref.watch(staffWordLessonsProvider)
        : ref.watch(staffSentenceLessonsProvider);
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Content Import',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
            body: ListView(
        padding: AppSpacing.listGutter,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'words', label: Text('Words')),
              ButtonSegment(value: 'sentences', label: Text('Sentences')),
            ],
            selected: {_contentType},
            onSelectionChanged: (value) => setState(() {
              _contentType = value.first;
              _lessonId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          lessonsAsync.when(
            loading: () => const LoadingState(kind: LoadingSkeletonKind.card),
            error: (e, _) => Text(e.toString()),
            data: (lessons) => DropdownButtonFormField<String>(
              value: _lessonId,
              decoration: const InputDecoration(labelText: 'Target lesson', border: OutlineInputBorder()),
              items: lessons
                  .map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text('${l.name} (${l.wordCount} items)'),
                      ))
                  .toList(),
              onChanged: (id) => setState(() => _lessonId = id),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bulk import', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Upload a DOCX or TXT file with lines like: You are ready. - Sen tayyorsan.\n'
                    'Optional: Task lines (Task 1: …) and embedded Word images are imported for sentences.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickAndParseDocx,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Pick DOCX / TXT'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('OCR import', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Photograph or scan a vocabulary list. When OCR is configured, pairs are extracted automatically.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickAndParseOcr,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Pick image for OCR'),
                  ),
                  if (_ocrImageUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _absoluteUrl(_ocrImageUrl!),
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  if (!_ocrEnabled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Material(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _statusMessage ??
                                    'OCR engine is not configured. Paste pairs manually below or use DOCX import.',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text('Manual paste', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('One pair per line: english - uzbek'),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _pasteController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'apple - olma\nbook - kitob',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _parsePastedPairs,
                    icon: const Icon(Icons.paste_outlined),
                    label: const Text('Parse pasted text'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _busy || _pairs.isEmpty || _lessonId == null ? null : _importPairs,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Import ${_pairs.length} pair(s)'),
          ),
          if (_pairs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            ..._pairs.take(8).map(
                  (pair) => ListTile(
                    dense: true,
                    title: Text(pair.english),
                    trailing: Text(pair.uzbek),
                  ),
                ),
            if (_pairs.length > 8) Text('...and ${_pairs.length - 8} more'),
          ],
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Media upload', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _uploadMedia(audio: false),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Upload image'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _uploadMedia(audio: true),
                    icon: const Icon(Icons.audiotrack_outlined),
                    label: const Text('Upload audio'),
                  ),
                ],
              ),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_statusMessage!, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  String _absoluteUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    return '$origin$path';
  }
}
