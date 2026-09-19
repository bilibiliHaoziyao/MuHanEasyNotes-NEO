// macOS HIG 风格 UI
// - 三栏布局（侧边栏 → 列表 → 详情编辑）
// - Unified Title Bar（Traffic Lights 区域）
// - SF Pro 字体
// - ⌘N 新建 / ⌘S 保存 / ⌘F 搜索

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../ui/shared/widgets.dart';

class MacOSApp extends StatefulWidget {
  const MacOSApp({super.key});

  @override
  State<MacOSApp> createState() => _MacOSAppState();
}

class _MacOSAppState extends State<MacOSApp> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConst.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(isMacOS: true),
      darkTheme: buildTheme(dark: true, isMacOS: true),
      home: Scaffold(
        body: Column(
          children: [
            _buildMacTitleBar(),
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacTitleBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
      child: Row(
        children: [
          // macOS Traffic Lights（视觉模拟，真实 mac 上 bitsdojo_window 会提供）
          Row(
            children: [
              _trafficLight(const Color(0xFFFF5F56)),
              const SizedBox(width: 6),
              _trafficLight(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _trafficLight(const Color(0xFF28C840)),
            ],
          ),
          const SizedBox(width: 20),
          Text(
            _sectionLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            AppConst.appNameEn,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trafficLight(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  String get _sectionLabel => const ['全部笔记', '置顶', '回收站', '设置'][_selectedSection];

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _sectionGroup('iCloud', [
            _sidebarItem(0, Icons.note_alt, '全部笔记', 0),
            _sidebarItem(1, Icons.push_pin, '置顶', 0),
          ]),
          const SizedBox(height: 8),
          _sectionGroup('', [
            _sidebarItem(2, Icons.delete, '回收站', 0),
          ]),
          const SizedBox(height: 8),
          _sectionGroup('', [
            _sidebarItem(3, Icons.settings, '设置…', null),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'v${AppConst.version}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ...children,
      ],
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label, int? count) {
    final selected = index == _selectedSection;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSection = index),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedSection) {
      case 0:
      case 1:
        return _buildThreeColumnLayout();
      case 2:
        return const Center(child: EmptyState(message: '回收站是空的'));
      case 3:
        return _buildSettings();
      default:
        return _buildThreeColumnLayout();
    }
  }

  Widget _buildThreeColumnLayout() {
    return Row(
      children: [
        // 笔记列表（第二栏）
        Container(
          width: 280,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SearchTextField(
                  placeholder: '搜索',
                ),
              ),
              Expanded(
                child: const EmptyState(
                  message: '无笔记',
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // 编辑面板（第三栏）
        Expanded(child: _buildEditor()),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                '编辑笔记',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '新建 (⌘N)',
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: '标题',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '写点什么…',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: ListView(
          children: [
            Text('偏好设置',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 24),
            _macSetting('深色模式', const CupertinoSwitch(value: false, onChanged: null)),
            _macSetting('语言', const Text('简体中文')),
            _macSetting('字体大小', const Text('标准')),
            const SizedBox(height: 24),
            Text('同步', style: Theme.of(context).textTheme.titleMedium),
            _macSetting('WebDAV 同步', const CupertinoSwitch(value: false, onChanged: null)),
          ],
        ),
      ),
    );
  }

  Widget _macSetting(String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final String placeholder;
  const SearchTextField({super.key, this.placeholder = '搜索'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search,
              size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: placeholder,
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
