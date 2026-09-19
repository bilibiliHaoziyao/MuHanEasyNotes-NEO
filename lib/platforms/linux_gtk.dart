// Linux GTK/Material 混合风格 UI
// - 左栏列表 + 右栏编辑
// - 适配 GNOME/KDE/XFCE 桌面环境
// - Ctrl+N 新建 / Ctrl+S 保存 / Ctrl+F 搜索

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../ui/shared/widgets.dart';

class LinuxApp extends StatefulWidget {
  const LinuxApp({super.key});

  @override
  State<LinuxApp> createState() => _LinuxAppState();
}

class _LinuxAppState extends State<LinuxApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
          children: [
            _buildSidebar(),
            const VerticalDivider(width: 1),
            Expanded(child: _buildEditorArea()),
          ],
        ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          // 顶部 AppBar 风格
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.sticky_note_2,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  AppConst.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 搜索
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: '搜索笔记…',
              leading: const Icon(Icons.search, size: 18),
              trailing: [
                const Icon(Icons.manage_search, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 分类列表
          Expanded(
            child: ListView(
              children: [
                _listItem(Icons.note_alt, '全部笔记', Icons.chevron_right),
                _listItem(Icons.push_pin, '置顶', null),
                _listItem(Icons.schedule, '最近', null),
                const Divider(height: 20),
                _listItem(Icons.folder_outlined, '标签', null),
                _listItem(Icons.delete_outline, '回收站', null),
              ],
            ),
          ),
          // 底部工具栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppConst.version,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: '新建笔记',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 18),
                  tooltip: '设置',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listItem(IconData icon, String label, IconData? trailing) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing != null ? Icon(trailing, size: 16) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {},
    );
  }

  Widget _buildEditorArea() {
    return Column(
      children: [
        // 顶部操作栏
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: '菜单',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Text(
                '编辑笔记',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: '保存 (Ctrl+S)',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('新建'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 编辑区
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: '标题',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '开始记录…（Ctrl+N 新建 / Ctrl+S 保存 / Ctrl+F 搜索）',
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
}
