import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/ielts.dart';

/// Shared dialog / form / list spacing for IELTS staff CMS screens
/// (Manage, Sources, Bank, Analytics, Access, Editor dialogs).
abstract final class IeltsUi {
  static const EdgeInsets dialogInset = AppSpacing.dialogInset;

  static const EdgeInsets titlePadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.xs,
    AppSpacing.lg,
    AppSpacing.xs,
  );

  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.lg,
  );

  static const SizedBox fieldGap = SizedBox(height: AppSpacing.fieldGap);

  /// Gap between list cards.
  static const double listGap = AppSpacing.sm;

  static const double dialogWidth = 520;
  static const double dialogWidthNarrow = 420;

  /// Prefer API `error.message` over raw DioException dumps.
  static String errorMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final msg = (data['error'] as Map)['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      }
      if (error.response?.statusCode == 400) {
        return 'Request rejected. Check exam structure and try again.';
      }
    }
    final s = error.toString();
    if (s.startsWith('DioException')) {
      return 'Something went wrong. Please try again.';
    }
    return s;
  }

  /// Client-side mirror of backend publish rules. Empty = ready.
  static List<String> publishBlockingIssues(IeltsExam exam) {
    final issues = <String>[];
    final mode = exam.mode;
    bool need(String skill) => mode == 'full' || mode == skill;
    final sections = exam.sections;

    if (need('reading')) {
      final reading = sections.where((s) => s.skill == 'reading').toList();
      if (reading.length != 3) {
        issues.add('Reading needs exactly 3 passages (found ${reading.length}).');
      } else {
        final parts = reading.map((s) => s.part).whereType<int>().where((p) => p >= 1 && p <= 3).toSet();
        if (parts.length < 3) {
          issues.add('Label passages as Passage 1, 2, and 3 in the editor.');
        }
      }
      final rq = reading.fold<int>(0, (n, s) => n + s.questions.length);
      if (rq != 40) {
        issues.add('Reading needs 40 questions (found $rq).');
      }
    }

    if (need('listening')) {
      final listening = sections.where((s) => s.skill == 'listening').toList();
      final parts = listening.map((s) => s.part).whereType<int>().where((p) => p >= 1 && p <= 4).toSet();
      if (![1, 2, 3, 4].every(parts.contains)) {
        issues.add('Listening needs Parts 1–4.');
      }
      for (final p in [1, 2, 3, 4]) {
        final n = listening.where((s) => s.part == p).fold<int>(0, (sum, s) => sum + s.questions.length);
        if (parts.contains(p) && n != 10) {
          issues.add('Listening Part $p needs 10 questions (found $n).');
        }
      }
    }

    if (need('writing')) {
      final writing = sections.where((s) => s.skill == 'writing').toList();
      final tasks = writing.map((s) => s.writingTask).whereType<String>().toSet();
      if (!tasks.contains('task1') || !tasks.contains('task2')) {
        issues.add('Writing needs Task 1 and Task 2 sections.');
      }
    }

    return issues;
  }

  static InputDecoration field(
    String label, {
    String? hint,
    bool dense = true,
    bool outline = true,
    bool alignHint = false,
  }) {
    // Always float labels with high-contrast colors — auto-float + dark dialogs
    // made Number/Type/Word limit labels nearly invisible on the border.
    const labelColor = Color(0xFFE2E8F0); // slate-200
    const floatingColor = Color(0xFFA5B4FC); // indigo-300
    const hintColor = Color(0xFF94A3B8); // slate-400

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      floatingLabelStyle: const TextStyle(
        color: floatingColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      hintStyle: const TextStyle(color: hintColor, fontSize: 13),
      border: outline ? const OutlineInputBorder() : null,
      enabledBorder: outline
          ? const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569)))
          : null,
      focusedBorder: outline
          ? const OutlineInputBorder(borderSide: BorderSide(color: floatingColor, width: 1.5))
          : null,
      isDense: dense,
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
    );
  }

  static BoxConstraints dialogConstraints(BuildContext context, {double maxWidth = dialogWidth}) {
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
    );
  }
}
