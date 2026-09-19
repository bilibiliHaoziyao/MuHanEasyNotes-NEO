import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'ui/wizard/migration_wizard.dart';

// 各平台独立 UI（仅返回 Scaffold/Widget，不在内部再创建 MaterialApp）
import 'platforms/windows_fluent.dart';
import 'platforms/macos_hig.dart';
import 'platforms/linux_gtk.dart';
import 'platforms/web_pwa.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MuHanNotesApp());
}

class MuHanNotesApp extends StatefulWidget {
  const MuHanNotesApp({super.key});

  @override
  State<MuHanNotesApp> createState() => _MuHanNotesAppState();
}

class _MuHanNotesAppState extends State<MuHanNotesApp> {
  bool _showMigration = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('migration_completed') ?? false;
    final shownBefore = prefs.getBool('migration_dialog_shown') ?? false;

    if (!completed && !shownBefore) {
      if (mounted) setState(() => _showMigration = true);
    }
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _onMigrationDone(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('migration_dialog_shown', true);
    if (completed) {
      await prefs.setBool('migration_completed', true);
    }
    if (mounted) setState(() => _showMigration = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    return MaterialApp(
      title: AppConst.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(isMacOS: isMac),
      darkTheme: buildTheme(dark: true, isMacOS: isMac),
      home: _initialized
          ? _buildHome()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }

  Widget _buildHome() {
    final home = _buildPlatformHome();
    if (_showMigration) {
      return Stack(
        children: [
          home,
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: MigrationWizard(
                onDone: _onMigrationDone,
              ),
            ),
          ),
        ],
      );
    }
    return home;
  }

  Widget _buildPlatformHome() {
    if (_isWeb) return const WebApp();
    if (_isMacOS) return const MacOSApp();
    if (_isWindows) return const WindowsApp();
    // Android / Linux / other desktop
    return const LinuxApp();
  }

  bool get _isWeb => kIsWeb;
  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}
