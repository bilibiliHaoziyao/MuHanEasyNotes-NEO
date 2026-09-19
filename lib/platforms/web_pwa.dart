// Web PWA 风格 UI
// - 响应式（320px - 2560px）
// - 小屏底部导航，大屏顶部
// - Service Worker 离线可用
// - 安装到桌面（manifest）

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../ui/shared/widgets.dart';

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  int _currentIndex = 0;
  bool _isWide = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConst.appName} - Web',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(dark: true),
      home: LayoutBuilder(
        builder: (context, constraints) {
          _isWide = constraints.maxWidth >= 720;
          return _isWide ? _buildWideLayout() : _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildWebNav(),
          Expanded(child: _buildMainArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('新建笔记'),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      body: _buildMainArea(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), label: '笔记'),
          NavigationDestination(icon: Icon(Icons.push_pin_outlined), label: '置顶'),
          NavigationDestination(icon: Icon(Icons.delete_outline), label: '回收站'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWebNav() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.sticky_note_2,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(
                  AppConst.appNameEn,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: '搜索笔记…',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _navItem(Icons.note_alt, '全部笔记', true),
                _navItem(Icons.push_pin, '置顶', false),
                _navItem(Icons.schedule, '最近修改', false),
                const Divider(height: 24),
                _navItem(Icons.delete_sweep, '回收站', false),
                _navItem(Icons.settings, '设置', false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              'v${AppConst.version} · PWA',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _currentIndex == 0 ? '全部笔记' : const ['笔记', '置顶', '回收站', '设置'][_currentIndex],
            ),
            centerTitle: false,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: const EmptyState(
              message: '欢迎使用 MuHanEasyNotes NEO\n点击右下角按钮开始写笔记',
            ),
          ),
        ),
      ],
    );
  }
}
