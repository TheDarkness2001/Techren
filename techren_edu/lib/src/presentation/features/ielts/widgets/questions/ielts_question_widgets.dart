import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_semantic_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../domain/entities/ielts.dart';

/// Dispatches to the typed IELTS question widget.
class IeltsQuestionView extends StatelessWidget {
  const IeltsQuestionView({
    super.key,
    required this.question,
    required this.value,
    required this.flagged,
    required this.onChanged,
    required this.onToggleFlag,
  });

  final IeltsQuestion question;
  final dynamic value;
  final bool flagged;
  final ValueChanged<dynamic> onChanged;
  final VoidCallback onToggleFlag;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(
          color: flagged ? AppColors.primary.withValues(alpha: 0.5) : context.semantic.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q${question.number}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.type.replaceAll('_', ' '),
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: flagged ? 'Unflag' : 'Flag for review',
                onPressed: onToggleFlag,
                icon: Icon(
                  flagged ? Icons.flag : Icons.flag_outlined,
                  color: flagged ? AppColors.primary : muted,
                ),
              ),
            ],
          ),
          if (question.instruction.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.instruction,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (question.isFutureLabeling) {
      final metadata = question.metadata;
      final imageUrl = metadata['imageUrl']?.toString();
      final hotspots = metadata['hotspots'];
      if (imageUrl != null && imageUrl.isNotEmpty && hotspots is List && hotspots.isNotEmpty) {
        return IeltsHotspotLabelingQuestion(question: question, value: value, onChanged: onChanged);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ComingSoonCard(
            message: 'No map/diagram image configured yet. Enter your label below for now.',
          ),
          IeltsTextAnswerQuestion(question: question, value: value, onChanged: onChanged),
        ],
      );
    }
    switch (question.type) {
      case 'mcq':
        return question.selectionMode == 'multiple'
            ? IeltsMultiMcqQuestion(question: question, value: value, onChanged: onChanged)
            : IeltsChoiceQuestion(question: question, value: value, onChanged: onChanged);
      case 'tfng':
      case 'ynng':
        return IeltsChoiceQuestion(question: question, value: value, onChanged: onChanged);
      case 'sentence_completion':
        return IeltsSentenceCompletionQuestion(question: question, value: value, onChanged: onChanged);
      case 'form_completion':
      case 'table_completion':
      case 'summary_completion':
        return IeltsBlankGroupQuestion(question: question, value: value, onChanged: onChanged);
      case 'matching':
      case 'matching_headings':
        return question.matchingStyle == 'drag_drop'
            ? IeltsDragDropMatchingQuestion(question: question, value: value, onChanged: onChanged)
            : IeltsMatchingQuestion(question: question, value: value, onChanged: onChanged);
      case 'short_answer':
      case 'map_labeling':
      case 'diagram_labeling':
      default:
        return IeltsTextAnswerQuestion(question: question, value: value, onChanged: onChanged);
    }
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
      ),
      child: Text(message, style: TextStyle(color: context.semantic.textMuted, fontSize: 13)),
    );
  }
}

class IeltsChoiceQuestion extends StatelessWidget {
  const IeltsChoiceQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = question.effectiveOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(question.prompt, style: const TextStyle(height: 1.4)),
          ),
        for (final opt in options)
          RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(opt),
            value: opt,
            groupValue: value?.toString(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
      ],
    );
  }
}

class IeltsMultiMcqQuestion extends StatelessWidget {
  const IeltsMultiMcqQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  List<String> get _selected {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value == null || value.toString().isEmpty) return [];
    return [value.toString()];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(question.prompt, style: const TextStyle(height: 1.4)),
          ),
        Text(
          'Select all that apply',
          style: TextStyle(color: context.semantic.textMuted, fontSize: 12),
        ),
        for (final opt in question.effectiveOptions)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(opt),
            value: selected.contains(opt),
            onChanged: (checked) {
              final next = [...selected];
              if (checked == true) {
                if (!next.contains(opt)) next.add(opt);
              } else {
                next.remove(opt);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class IeltsTextAnswerQuestion extends StatefulWidget {
  const IeltsTextAnswerQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<IeltsTextAnswerQuestion> createState() => _IeltsTextAnswerQuestionState();
}

class _IeltsTextAnswerQuestionState extends State<IeltsTextAnswerQuestion> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant IeltsTextAnswerQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value?.toString() ?? '';
    if (next != _controller.text) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.question.prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.question.prompt, style: const TextStyle(height: 1.4)),
          ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'Your answer',
          ),
          textInputAction: TextInputAction.done,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

/// Renders prompt with ________ blank filled by a short TextField.
class IeltsSentenceCompletionQuestion extends StatefulWidget {
  const IeltsSentenceCompletionQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<IeltsSentenceCompletionQuestion> createState() => _IeltsSentenceCompletionQuestionState();
}

class _IeltsSentenceCompletionQuestionState extends State<IeltsSentenceCompletionQuestion> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant IeltsSentenceCompletionQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value?.toString() ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.question.prompt;
    final parts = prompt.split(RegExp(r'_{2,}|\[\s*\]|\{\s*\}'));
    final hasBlank = parts.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasBlank)
          Text(prompt, style: const TextStyle(height: 1.45))
        else
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                Text(parts[i], style: const TextStyle(height: 1.45, fontSize: 15)),
                if (i < parts.length - 1)
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
                      onChanged: widget.onChanged,
                    ),
                  ),
              ],
            ],
          ),
        if (!hasBlank) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Complete the sentence',
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}

class IeltsBlankGroupQuestion extends StatefulWidget {
  const IeltsBlankGroupQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<IeltsBlankGroupQuestion> createState() => _IeltsBlankGroupQuestionState();
}

class _IeltsBlankGroupQuestionState extends State<IeltsBlankGroupQuestion> {
  late Map<String, TextEditingController> _controllers;

  Map<String, String> get _map {
    if (widget.value is Map) {
      return widget.value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  List<IeltsBlank> get _blanks {
    if (widget.question.blanks.isNotEmpty) return widget.question.blanks;
    // Fallback: single blank from prompt or "b1"
    return [IeltsBlank(id: 'b1', label: widget.question.prompt.isEmpty ? 'Answer' : widget.question.prompt)];
  }

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final b in _blanks) b.id: TextEditingController(text: _map[b.id] ?? ''),
    };
  }

  @override
  void didUpdateWidget(covariant IeltsBlankGroupQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final b in _blanks) {
      _controllers.putIfAbsent(b.id, () => TextEditingController());
      final next = _map[b.id] ?? '';
      if (_controllers[b.id]!.text != next) _controllers[b.id]!.text = next;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final out = <String, String>{};
    for (final e in _controllers.entries) {
      out[e.key] = e.value.text;
    }
    // Single blank with no structured blanks → also store flat string for legacy scoring
    if (_blanks.length == 1 && widget.question.blanks.isEmpty) {
      widget.onChanged(out[_blanks.first.id] ?? '');
    } else {
      widget.onChanged(out);
    }
  }

  @override
  Widget build(BuildContext context) {
    final html = widget.question.contentHtml;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.question.prompt.isNotEmpty && widget.question.blanks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.question.prompt, style: const TextStyle(height: 1.4)),
          ),
        if (html.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(html.replaceAll(RegExp(r'<[^>]*>'), ''), style: const TextStyle(height: 1.4)),
          ),
        if (widget.question.type == 'table_completion' || widget.question.layout == 'table')
          Table(
            border: TableBorder.all(color: context.semantic.border),
            children: [
              for (final b in _blanks)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(b.label.isEmpty ? b.id : b.label),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _controllers[b.id],
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        onChanged: (_) => _emit(),
                      ),
                    ),
                  ],
                ),
            ],
          )
        else
          for (final b in _blanks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _controllers[b.id],
                decoration: InputDecoration(
                  labelText: b.label.isEmpty ? 'Blank ${b.order + 1}' : b.label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _emit(),
              ),
            ),
      ],
    );
  }
}

class IeltsMatchingQuestion extends StatelessWidget {
  const IeltsMatchingQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  List<String> get _stems {
    final fromMeta = question.metadata['stems'] ?? question.metadata['paragraphs'];
    if (fromMeta is List && fromMeta.isNotEmpty) {
      return fromMeta.map((e) => e.toString()).toList();
    }
    if (question.prompt.contains('\n')) {
      return question.prompt.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [question.prompt.isEmpty ? 'Item' : question.prompt];
  }

  List<String> get _choices => question.matchingChoices;

  Map<String, String> get _map {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    if (value != null && value.toString().isNotEmpty && _stems.length == 1) {
      return {_stems.first: value.toString()};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final map = Map<String, String>.from(_map);
    final style = question.matchingStyle;
    final choices = _choices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.type == 'matching_headings')
          Text(
            'Choose a heading for each paragraph',
            style: TextStyle(color: context.semantic.textMuted, fontSize: 12),
          ),
        const SizedBox(height: 8),
        for (var i = 0; i < _stems.length; i++) ...[
          Text(
            question.type == 'matching_headings' && !_stems[i].startsWith('Paragraph')
                ? 'Paragraph ${String.fromCharCode(65 + i)} — ${_stems[i]}'
                : _stems[i],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (style == 'cards' && choices.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in choices)
                  ChoiceChip(
                    label: Text(c, maxLines: 2, overflow: TextOverflow.ellipsis),
                    selected: map[_stems[i]] == c,
                    onSelected: (_) {
                      map[_stems[i]] = c;
                      onChanged(_stems.length == 1 ? c : Map<String, String>.from(map));
                    },
                  ),
              ],
            )
          else
            DropdownButtonFormField<String>(
              value: map[_stems[i]]?.isNotEmpty == true && choices.contains(map[_stems[i]])
                  ? map[_stems[i]]
                  : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Select',
              ),
              items: [
                for (final c in choices) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                if (v == null) return;
                map[_stems[i]] = v;
                onChanged(_stems.length == 1 ? v : Map<String, String>.from(map));
              },
            ),
          const SizedBox(height: 12),
        ],
        if (choices.isEmpty)
          IeltsTextAnswerQuestion(question: question, value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Drag & drop variant of matching: choices are draggable chips; each stem is
/// a drop target. Used when [IeltsQuestion.matchingStyle] == 'drag_drop'.
class IeltsDragDropMatchingQuestion extends StatelessWidget {
  const IeltsDragDropMatchingQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  List<String> get _stems {
    final fromMeta = question.metadata['stems'] ?? question.metadata['paragraphs'];
    if (fromMeta is List && fromMeta.isNotEmpty) {
      return fromMeta.map((e) => e.toString()).toList();
    }
    if (question.prompt.contains('\n')) {
      return question.prompt.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [question.prompt.isEmpty ? 'Item' : question.prompt];
  }

  List<String> get _choices => question.matchingChoices;

  Map<String, String> get _map {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    if (value != null && value.toString().isNotEmpty && _stems.length == 1) {
      return {_stems.first: value.toString()};
    }
    return {};
  }

  void _emit(Map<String, String> map) {
    onChanged(_stems.length == 1 ? (map[_stems.first] ?? '') : Map<String, String>.from(map));
  }

  @override
  Widget build(BuildContext context) {
    final stems = _stems;
    final choices = _choices;
    if (choices.isEmpty) {
      return IeltsTextAnswerQuestion(question: question, value: value, onChanged: onChanged);
    }
    final map = Map<String, String>.from(_map);
    final muted = context.semantic.textMuted;

    return StatefulBuilder(
      builder: (context, setLocal) {
        void drop(String stem, String choice) {
          setLocal(() {
            map[stem] = choice;
          });
          _emit(map);
        }

        void clear(String stem) {
          setLocal(() {
            map.remove(stem);
          });
          _emit(map);
        }

        final usedNow = map.values.where((v) => v.isNotEmpty).toSet();
        final pool = choices.where((c) => !usedNow.contains(c)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.type == 'matching_headings')
              Text(
                'Drag a heading onto each paragraph',
                style: TextStyle(color: muted, fontSize: 12),
              )
            else
              Text('Drag an option onto each item', style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 8),
            for (var i = 0; i < stems.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      question.type == 'matching_headings' && !stems[i].startsWith('Paragraph')
                          ? 'Paragraph ${String.fromCharCode(65 + i)} — ${stems[i]}'
                          : stems[i],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DragTarget<String>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) => drop(stems[i], details.data),
                    builder: (context, candidateData, rejectedData) {
                      final filled = map[stems[i]];
                      final highlighted = candidateData.isNotEmpty;
                      return Container(
                        width: 160,
                        constraints: const BoxConstraints(minHeight: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: highlighted ? AppColors.primary : context.semantic.border,
                            width: highlighted ? 2 : 1,
                          ),
                        ),
                        child: filled == null || filled.isEmpty
                            ? Text('Drop here', style: TextStyle(color: muted, fontSize: 12))
                            : Row(
                                children: [
                                  Expanded(child: Text(filled, style: const TextStyle(fontSize: 13))),
                                  InkWell(
                                    onTap: () => clear(stems[i]),
                                    child: Icon(Icons.close, size: 16, color: muted),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text('Available options', style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in pool)
                  Draggable<String>(
                    data: c,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _MatchingChoiceChip(label: c, color: AppColors.primary),
                    ),
                    childWhenDragging: _MatchingChoiceChip(label: c, color: context.semantic.border, faded: true),
                    child: _MatchingChoiceChip(label: c, color: AppColors.primary),
                  ),
                if (pool.isEmpty) Text('All options placed', style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MatchingChoiceChip extends StatelessWidget {
  const _MatchingChoiceChip({required this.label, required this.color, this.faded = false});
  final String label;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

/// Map/diagram labeling backed by an image with fractional hotspot regions.
/// Expects `metadata.imageUrl` (String) and `metadata.hotspots`
/// (`[{id, label, x, y, w, h}]`, fractions 0-1 of image width/height).
class IeltsHotspotLabelingQuestion extends StatelessWidget {
  const IeltsHotspotLabelingQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final IeltsQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  List<Map<String, dynamic>> get _hotspots {
    final raw = question.metadata['hotspots'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = question.metadata['imageUrl']?.toString() ?? '';
    final hotspots = _hotspots;
    final selected = value?.toString();
    final muted = context.semantic.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(question.prompt, style: const TextStyle(height: 1.4)),
          ),
        Text('Tap the label on the image that matches this item', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: (question.metadata['imageAspectRatio'] as num?)?.toDouble() ?? 4 / 3,
          child: ClipRRect(
            borderRadius: AppRadius.card,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                Image.network(
                  imageUrl,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stack) =>
                      Center(child: Icon(Icons.broken_image_outlined, color: muted)),
                ),
                for (final h in hotspots)
                  Builder(builder: (context) {
                    final id = h['id']?.toString() ?? h['label']?.toString() ?? '';
                    final label = h['label']?.toString() ?? id;
                    final isSelected = selected == label || selected == id;
                    final x = (h['x'] as num?)?.toDouble() ?? 0;
                    final y = (h['y'] as num?)?.toDouble() ?? 0;
                    final w = (h['w'] as num?)?.toDouble() ?? 0.08;
                    final hh = (h['h'] as num?)?.toDouble() ?? 0.08;
                    return LayoutBuilder(builder: (context, constraints) {
                      return Positioned(
                        left: x * constraints.maxWidth,
                        top: y * constraints.maxHeight,
                        width: w * constraints.maxWidth,
                        height: hh * constraints.maxHeight,
                        child: InkWell(
                          onTap: () => onChanged(label),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.08),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final h in hotspots)
              Builder(builder: (context) {
                final id = h['id']?.toString() ?? h['label']?.toString() ?? '';
                final label = h['label']?.toString() ?? id;
                final isSelected = selected == label || selected == id;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(label),
                );
              }),
          ],
        ),
      ],
    );
  }
}
