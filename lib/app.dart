import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';

class GlazeVaultApp extends ConsumerWidget {
  const GlazeVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: 'Vitrify',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}

// ── Semantic status/outcome colors ─────────────────────────────────────────────
// Earthy palette that reads well in both light and dark, consistent with the
// terracotta + teal brand palette.

const kColorTested     = Color(0xFF4D8B6A); // sage green — success / complete
const kColorTesting    = Color(0xFFC87B3A); // warm amber — in progress
const kColorPass       = Color(0xFF4D8B6A); // sage green
const kColorFail       = Color(0xFFB04030); // terracotta red
const kColorPromising  = Color(0xFF3D7BAB); // slate blue
const kColorInteresting = Color(0xFF7B5EA7); // warm purple
const kColorProblematic = Color(0xFFC87B3A); // amber

Color statusColor(String status) => switch (status) {
  'Tested'      => kColorTested,
  'Testing'     => kColorTesting,
  'Pass'        => kColorPass,
  'Fail'        => kColorFail,
  'Promising'   => kColorPromising,
  'Interesting' => kColorInteresting,
  'Problematic' => kColorProblematic,
  _             => const Color(0xFF8A8A8A),
};

// ── Theme builder ──────────────────────────────────────────────────────────────

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Seed: rich terracotta pulled from the logo's brick/kiln arch colour.
  // M3 generates warm primary tones; the tertiary naturally lands in an
  // olive/amber range which complements the teal glaze accent.
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF9C4A22),
    brightness: brightness,
  );

  // Base text theme that holds the correct adaptive colours for the mode
  final base = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

  // DM Sans for all body / UI text; Lora for display / headline / titleLarge
  final textTheme = GoogleFonts.dmSansTextTheme(base).copyWith(
    displayLarge:  GoogleFonts.lora(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.lora(textStyle: base.displayMedium),
    displaySmall:  GoogleFonts.lora(textStyle: base.displaySmall),
    headlineLarge:  GoogleFonts.lora(textStyle: base.headlineLarge),
    headlineMedium: GoogleFonts.lora(textStyle: base.headlineMedium),
    headlineSmall:  GoogleFonts.lora(textStyle: base.headlineSmall),
    titleLarge: GoogleFonts.lora(textStyle: base.titleLarge),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: textTheme,

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.primary,
      titleTextStyle: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
    ),

    // ── Cards ─────────────────────────────────────────────────────────────────
    // Flat, bordered cards — no shadow, subtle outline, generous radius.
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Navigation bar ────────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),

    // ── Chips ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
    ),

    // ── FAB ───────────────────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      elevation: 2,
      focusElevation: 4,
      hoverElevation: 4,
    ),

    // ── Inputs ────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      labelStyle: GoogleFonts.dmSans(fontSize: 14),
      hintStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    // ── Bottom sheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: colorScheme.outlineVariant,
      dragHandleSize: const Size(40, 4),
      clipBehavior: Clip.antiAlias,
    ),

    // ── Dialogs ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: -0.1,
      ),
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    ),

    // ── Snack bars ────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // ── Tab bar ───────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    ),

    // ── List tiles ────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: GoogleFonts.dmSans(
        fontSize: 13,
        color: colorScheme.onSurfaceVariant,
      ),
    ),

    // ── Filled buttons ────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    // ── Text buttons ──────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    // ── Dividers ──────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),

    // ── Progress indicators ───────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      circularTrackColor: colorScheme.surfaceContainerHighest,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(8),
    ),

    // ── Switches ─────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return colorScheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.surfaceContainerHighest;
      }),
    ),

    // ── Popup menus ───────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      textStyle: GoogleFonts.dmSans(fontSize: 14, color: colorScheme.onSurface),
    ),
  );
}
