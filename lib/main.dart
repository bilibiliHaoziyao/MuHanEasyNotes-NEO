import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'ui/wizard/migration_wizard.dart';

// 各平台独立 UI
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

  @override
  void initState() {
    super.initState();
    // 首次启动时检查是否需要迁移
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowMigration();
    });
  }

  Future<void> _checkAndShowMigration() async {
    // 实际实现中通过 Rust 核心层检测
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showMigration = true);
  }

  @override
  Widget build(BuildContext context) {
    final platformHome = _buildPlatformHome();
    return MaterialApp(
      title: AppConst.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(isMacOS: _isMacOS),
      darkTheme: buildTheme(dark: true, isMacOS: _isMacOS),
      home: Stack(
        children: [
          platformHome,
          if (_showMigration)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: MigrationWizard(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformHome() {
    if (_isWeb) return const WebApp();
    if (_isMacOS) return const MacOSApp();
    if (_isWindows) return const WindowsApp();
    return const LinuxApp();
  }

  bool get _isWeb => kIsWeb;
  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  // Linux 作为默认 fallback
}
