import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../ui/shared/widgets.dart';

class WindowsApp extends StatefulWidget {
  const WindowsApp({super.key});

  @override
  State<WindowsApp> createState() => _WindowsAppState();
}

class _WindowsAppState extends State<WindowsApp> {
  int _selectedIndex = 0;
  final _queryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConst.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(dark: true),
      home: Scaffold(
        body: Row(
          children: [
            _buildNavRail(),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.note_alt_outlined),
          selectedIcon: Icon(Icons.note_alt),
          label: Text('笔记'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.push_pin_outlined),
          selectedIcon: Icon(Icons.push_pin),
          label: Text('置顶'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.delete_outline),
          selectedIcon: Icon(Icons.delete),
          label: Text('回收站'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: '关于',
              onPressed: _showAbout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildNotesView();
      case 1:
        return _buildNotesView(pinnedOnly: true);
      case 2:
        return const _TrashView();
      case 3:
        return const _SettingsView();
      default:
        return _buildNotesView();
    }
  }

  Widget _buildNotesView({bool pinnedOnly = false}) {
    return Column(
      children: [
        _TitleBar(pinnedOnly ? '置顶笔记' : '全部笔记'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: '搜索笔记',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: TextButton.icon(
                  onPressed: _newNote,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建'),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ),
        const Expanded(child: EmptyState(message: '还没有笔记\n点击上方"新建"按钮开始')),
      ],
    );
  }

  void _newNote() {}

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppConst.appName,
      applicationVersion: AppConst.version,
      applicationIcon: const FlutterLogo(size: 48),
      children: const [Text('一款跨平台轻量笔记应用\n基于 Flutter + Rust')],
    );
  }
}

class _TitleBar extends StatelessWidget {
  final String title;
  const _TitleBar(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TrashView extends StatelessWidget {
  const _TrashView();
  @override
  Widget build(BuildContext context) => const Column(
        children: [
          _TitleBar('回收站'),
          Expanded(child: EmptyState(message: '回收站是空的')),
        ],
      );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('外观', [
          const _SettingTile(title: '深色模式', trailing: _ToggleSwitch()),
          const _SettingTile(title: '界面缩放', trailing: _ScaleControl()),
        ]),
        const SizedBox(height: 16),
        _section('数据', [
          _SettingTile(
            title: '导出备份',
            trailing: FilledButton.tonal(
              onPressed: () {},
              child: const Text('导出'),
            ),
          ),
          _SettingTile(
            title: '导入备份',
            trailing: FilledButton.tonal(
              onPressed: () {},
              child: const Text('导入'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _section('同步', [
          const _SettingTile(title: 'WebDAV 同步', trailing: _ToggleSwitch()),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final Widget trailing;
  const _SettingTile({required this.title, required this.trailing});
  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title), trailing: trailing);
  }
}

class _ToggleSwitch extends StatefulWidget {
  const _ToggleSwitch();
  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  bool _v = false;
  @override
  Widget build(BuildContext context) => Switch(
        value: _v,
        onChanged: (v) => setState(() => _v = v),
      );
}

class _ScaleControl extends StatefulWidget {
  const _ScaleControl();
  @override
  State<_ScaleControl> createState() => _ScaleControlState();
}

class _ScaleControlState extends State<_ScaleControl> {
  double _v = 1.0;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: Row(
          children: [
            Text('${_v.toStringAsFixed(1)}x'),
            Expanded(
              child: Slider(
                value: _v,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                onChanged: (v) => setState(() => _v = v),
              ),
            ),
          ],
        ),
      );
}
