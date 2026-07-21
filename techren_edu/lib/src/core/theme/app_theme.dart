import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class _ThemeTokens {
  const _ThemeTokens({
    required this.scaffoldBackground,
    required this.canvas,
    required this.divider,
    required this.surface,
    required this.card,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.surfaceContainer,
    required this.surfaceContainerHighest,
    required this.inputFill,
    required this.primary,
    required this.primaryHover,
    required this.primaryContainer,
    required this.onPrimary,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.snackBarBackground,
    required this.semantic,
    required this.overlayStyle,
  });

  final Color scaffoldBackground;
  final Color canvas;
  final Color divider;
  final Color surface;
  final Color card;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color surfaceContainer;
  final Color surfaceContainerHighest;
  final Color inputFill;
  final Color primary;
  final Color primaryHover;
  final Color primaryContainer;
  final Color onPrimary;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color snackBarBackground;
  final AppSemanticColors semantic;
  final SystemUiOverlayStyle overlayStyle;

  static const light = _ThemeTokens(
    scaffoldBackground: AppColors.background,
    canvas: AppColors.surface,
    divider: AppColors.divider,
    surface: AppColors.surface,
    card: AppColors.card,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textDisabled: AppColors.textDisabled,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    inputFill: AppColors.inputFill,
    primary: AppColors.primary,
    primaryHover: AppColors.primaryHover,
    primaryContainer: AppColors.primaryContainer,
    onPrimary: AppColors.onPrimary,
    danger: AppColors.danger,
    dangerContainer: AppColors.dangerContainer,
    onDangerContainer: AppColors.onDangerContainer,
    snackBarBackground: AppColors.textPrimary,
    semantic: AppSemanticColors.light,
    overlayStyle: SystemUiOverlayStyle.dark,
  );

  static const dark = _ThemeTokens(
    scaffoldBackground: AppColorsDark.background,
    canvas: AppColorsDark.surface,
    divider: AppColorsDark.divider,
    surface: AppColorsDark.surface,
    card: AppColorsDark.card,
    border: AppColorsDark.border,
    borderStrong: AppColorsDark.borderStrong,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    textMuted: AppColorsDark.textMuted,
    textDisabled: AppColorsDark.textDisabled,
    surfaceContainer: AppColorsDark.surfaceContainer,
    surfaceContainerHighest: AppColorsDark.surfaceContainerHighest,
    inputFill: AppColorsDark.inputFill,
    primary: AppColorsDark.primary,
    primaryHover: AppColorsDark.primaryHover,
    primaryContainer: AppColorsDark.primaryContainer,
    onPrimary: AppColorsDark.onPrimary,
    danger: AppColorsDark.danger,
    dangerContainer: AppColorsDark.dangerContainer,
    onDangerContainer: AppColorsDark.onDangerContainer,
    snackBarBackground: AppColorsDark.surfaceContainerHigh,
    semantic: AppSemanticColors.dark,
    overlayStyle: SystemUiOverlayStyle.light,
  );
}

/// Material 3 ThemeData — light & dark, one design language.
class AppTheme {
  static ThemeData light() => _buildTheme(_lightColorScheme(), _ThemeTokens.light);

  static ThemeData dark() => _buildTheme(_darkColorScheme(), _ThemeTokens.dark);

  static ThemeData _buildTheme(ColorScheme colorScheme, _ThemeTokens tokens) {
    final textTheme = AppTypography.textTheme(colorScheme);
    final secondaryButtonBg = tokens.surfaceContainer;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryColor: tokens.primary,
      scaffoldBackgroundColor: tokens.scaffoldBackground,
      canvasColor: tokens.canvas,
      dividerColor: tokens.divider,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [tokens.semantic],
      iconTheme: IconThemeData(size: 22, color: tokens.textSecondary),
      primaryIconTheme: IconThemeData(size: 22, color: tokens.primary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.primary,
        selectionColor: tokens.primary.withValues(alpha: 0.22),
        selectionHandleColor: tokens.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ── App bar / glass nav ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: tokens.surface.withValues(alpha: 0.92),
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x0A0F172A),
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: 56,
        systemOverlayStyle: tokens.overlayStyle,
        iconTheme: IconThemeData(size: 22, color: tokens.textSecondary),
        actionsIconTheme: IconThemeData(size: 22, color: tokens.textSecondary),
        shape: Border(
          bottom: BorderSide(color: tokens.border.withValues(alpha: 0.55)),
        ),
      ),

      // ── Surfaces ───────────────────────────────────────────────────────
      cardTheme: CardTheme(
        elevation: 0,
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x0A0F172A),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: tokens.border.withValues(alpha: 0.65)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
        constraints: const BoxConstraints(minHeight: 52),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: tokens.primary),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIconColor: tokens.textMuted,
        suffixIconColor: tokens.textMuted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
        ),
      ),

      // ── Buttons ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          elevation: 0,
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          disabledBackgroundColor: tokens.primary.withValues(alpha: 0.4),
          disabledForegroundColor: tokens.onPrimary.withValues(alpha: 0.7),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return tokens.primary.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
              return tokens.primaryHover;
            }
            return tokens.primary;
          }),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: secondaryButtonBg,
          foregroundColor: tokens.textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          side: BorderSide(color: tokens.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          foregroundColor: tokens.textPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          foregroundColor: tokens.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          foregroundColor: tokens.textSecondary,
          hoverColor: tokens.primaryContainer.withValues(alpha: 0.55),
          focusColor: tokens.primaryContainer.withValues(alpha: 0.7),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 2,
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),

      // ── Navigation ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: tokens.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x0A0F172A),
        indicatorColor: tokens.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? tokens.primary : tokens.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? tokens.primary : tokens.textMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.semantic.sidebarBackground,
        elevation: 0,
        selectedIconTheme: IconThemeData(size: 24, color: tokens.semantic.sidebarIconSelected),
        unselectedIconTheme: IconThemeData(size: 24, color: tokens.semantic.sidebarIcon),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: tokens.semantic.sidebarIconSelected),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: tokens.semantic.sidebarText),
        indicatorColor: tokens.semantic.sidebarSelected,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.navIndicator),
        labelType: NavigationRailLabelType.all,
        minWidth: 72,
        minExtendedWidth: 220,
        useIndicator: true,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: tokens.semantic.sidebarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: tokens.semantic.sidebarSelected,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.navIndicator),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelLarge?.copyWith(
            color: selected ? tokens.semantic.sidebarIconSelected : tokens.semantic.sidebarText,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? tokens.semantic.sidebarIconSelected : tokens.semantic.sidebarIcon,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.semantic.sidebarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.lg)),
        ),
      ),

      // ── Overlays ───────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        elevation: 0,
        backgroundColor: tokens.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: tokens.border,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(tokens.card),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: tokens.snackBarBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.primaryLight,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.brightness == Brightness.dark
              ? AppColorsDark.background
              : AppColors.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // ── Selection controls ─────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(tokens.onPrimary),
        side: BorderSide(color: tokens.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.onPrimary;
          return tokens.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.primary,
        inactiveTrackColor: tokens.surfaceContainer,
        thumbColor: tokens.primary,
        overlayColor: tokens.primary.withValues(alpha: 0.12),
        valueIndicatorColor: tokens.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // ── Chips / tabs / lists ───────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceContainer,
        selectedColor: tokens.primaryContainer,
        disabledColor: tokens.surfaceContainer.withValues(alpha: 0.5),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelSmall!,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 0),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        side: BorderSide(color: tokens.border.withValues(alpha: 0.7)),
        showCheckmark: false,
        selectedShadowColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.surfaceContainer,
        circularTrackColor: tokens.surfaceContainer,
        linearMinHeight: 6,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: tokens.primary,
        unselectedLabelColor: tokens.textMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: tokens.primary,
        dividerColor: tokens.divider,
        overlayColor: WidgetStateProperty.all(tokens.primaryContainer.withValues(alpha: 0.35)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listItemPadding,
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        minVerticalPadding: AppSpacing.xs,
        selectedTileColor: tokens.primaryContainer,
        selectedColor: tokens.primary,
      ),

      // ── Data table ─────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(tokens.surfaceContainer),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return tokens.primaryContainer.withValues(alpha: 0.35);
          }
          if (states.contains(WidgetState.selected)) {
            return tokens.primaryContainer.withValues(alpha: 0.55);
          }
          return null;
        }),
        headingTextStyle: textTheme.labelLarge?.copyWith(color: tokens.textSecondary),
        dataTextStyle: textTheme.bodyMedium,
        dividerThickness: 0.5,
        headingRowHeight: 48,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          border: Border.all(color: tokens.border.withValues(alpha: 0.7)),
        ),
      ),

      // ── Scroll / pickers ───────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(tokens.textMuted.withValues(alpha: 0.45)),
        radius: const Radius.circular(AppRadius.pill),
        thickness: WidgetStateProperty.all(6),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
        interactive: true,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: tokens.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: tokens.primaryContainer,
        headerForegroundColor: tokens.primary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.onPrimary;
          if (states.contains(WidgetState.disabled)) return tokens.textDisabled;
          return tokens.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(tokens.primary),
        todayBorder: BorderSide(color: tokens.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: tokens.card,
        dialBackgroundColor: tokens.surfaceContainer,
        hourMinuteColor: tokens.primaryContainer,
        hourMinuteTextColor: tokens.primary,
        dayPeriodColor: tokens.primaryContainer,
        dayPeriodTextColor: tokens.primary,
        entryModeIconColor: tokens.textSecondary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: tokens.inputFill,
          border: OutlineInputBorder(
            borderRadius: AppRadius.inputBorder,
            borderSide: BorderSide(color: tokens.border),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(tokens.card),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.card),
          ),
        ),
      ),
    );
  }

  static ColorScheme _lightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.warning,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.warningContainer,
      onTertiaryContainer: AppColors.onWarningContainer,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.dangerContainer,
      onErrorContainer: AppColors.onDangerContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: Color(0x140F172A),
      scrim: Color(0x660F172A),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: AppColors.primary,
    );
  }

  static ColorScheme _darkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      onPrimaryContainer: AppColorsDark.onPrimaryContainer,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.onSecondary,
      secondaryContainer: AppColorsDark.secondaryContainer,
      onSecondaryContainer: AppColorsDark.onSecondaryContainer,
      tertiary: AppColorsDark.tertiary,
      onTertiary: Color(0xFF422006),
      tertiaryContainer: AppColorsDark.tertiaryContainer,
      onTertiaryContainer: AppColorsDark.onWarningContainer,
      error: AppColorsDark.danger,
      onError: Color(0xFF450A0A),
      errorContainer: AppColorsDark.dangerContainer,
      onErrorContainer: AppColorsDark.onDangerContainer,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      onSurfaceVariant: AppColorsDark.textSecondary,
      outline: AppColorsDark.outline,
      outlineVariant: AppColorsDark.outlineVariant,
      shadow: Color(0x330F172A),
      scrim: Color(0x990F172A),
      inverseSurface: AppColorsDark.textPrimary,
      onInverseSurface: AppColorsDark.background,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColorsDark.primary,
    );
  }
}
