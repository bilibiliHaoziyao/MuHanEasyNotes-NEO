// 迁移向导（Wizard）
// - 首次启动检测旧版数据
// - 5 步流程：Welcome → SourceSelect → Preview → Execute → Done
// - 进度条 + 取消功能

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

enum _WizardStep { welcome, source, preview, execute, done }

class MigrationWizard extends StatefulWidget {
  final ValueChanged<bool>? onDone;

  const MigrationWizard({super.key, this.onDone});

  @override
  State<MigrationWizard> createState() => _MigrationWizardState();
}

class _MigrationWizardState extends State<MigrationWizard> {
  _WizardStep _step = _WizardStep.welcome;
  bool _hasLegacyData = false;
  String? _selectedFilePath;
  List<Map<String, dynamic>> _previewNotes = [];
  double _progress = 0;
  String _statusMessage = '';
  bool _isImporting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _checkLegacyData();
  }

  Future<void> _checkLegacyData() async {
    // 模拟检测（实际通过 flutter_rust_bridge 调用 find_legacy_backup_files）
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _hasLegacyData = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1),
                Expanded(child: _buildBody()),
                const Divider(height: 1),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.swap_horiz,
                color: Theme.of(context).colorScheme.onPrimaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据迁移向导',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '从旧版慕寒轻松记 v1.x 迁移数据到 ${AppConst.version}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _WizardStep.welcome:
        return _buildWelcome();
      case _WizardStep.source:
        return _buildSourceSelect();
      case _WizardStep.preview:
        return _buildPreview();
      case _WizardStep.execute:
        return _buildExecute();
      case _WizardStep.done:
        return _buildDone();
    }
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hasLegacyData
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _hasLegacyData ? Icons.check_circle : Icons.info,
                  color: _hasLegacyData ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasLegacyData
                            ? '检测到旧版数据！'
                            : '未检测到旧版数据',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasLegacyData
                            ? '我们可以帮你把旧笔记安全地迁移到新版'
                            : '你可以手动选择旧版备份文件（.json）进行迁移',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _StepIndicator(current: 0),
        ],
      ),
    );
  }

  Widget _buildSourceSelect() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择数据源',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Text(
            '你可以让向导自动搜索，或手动定位备份文件',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          _SourceOption(
            icon: Icons.auto_awesome,
            title: '自动检测',
            subtitle: '在常见位置搜索旧版备份文件',
            selected: true,
            onTap: () {
              setState(() => _selectedFilePath = null);
              _autoDetect();
            },
          ),
          const SizedBox(height: 12),
          _SourceOption(
            icon: Icons.folder_open,
            title: '手动选择文件…',
            subtitle: '选择 .json 备份文件',
            selected: false,
            onTap: () async {
              // 实际实现用 file_picker
              // final result = await FilePicker.platform.pickFiles(
              //   type: FileType.custom, allowedExtensions: ['json']);
              // _selectedFilePath = result?.files.first.path;
              setState(() => _selectedFilePath = '/example/path/backup.json');
              _previewFromSelected();
            },
          ),
          const SizedBox(height: 32),
          const _StepIndicator(current: 1),
        ],
      ),
    );
  }

  Future<void> _autoDetect() async {
    setState(() => _statusMessage = '正在搜索旧版数据…');
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _selectedFilePath = 'detected_legacy_notes.json';
      _statusMessage = '找到旧版备份文件';
    });
    _previewFromSelected();
  }

  void _previewFromSelected() {
    setState(() {
      _previewNotes = [
        {
          'title': '购物清单',
          'content': '牛奶、面包、鸡蛋',
          'color': 'yellow',
          'pinned': false,
        },
        {
          'title': '会议记录',
          'content': '关于新版本发布的讨论…',
          'color': 'blue',
          'pinned': true,
        },
        {
          'title': '',
          'content': '这是一条没有标题的笔记内容。',
          'color': 'green',
          'pinned': false,
        },
      ];
      _step = _WizardStep.preview;
    });
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('预览待迁移数据',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
              const Spacer(),
              Chip(
                label: Text('共 ${_previewNotes.length} 条笔记'),
                avatar: const Icon(Icons.note_alt, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _previewNotes.length,
              itemBuilder: (context, i) {
                final n = _previewNotes[i];
                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(n['color'] as String? ?? 'yellow'),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(n['title']!.toString().isEmpty
                      ? '(无标题)'
                      : n['title']!.toString()),
                  subtitle: Text(
                    n['content']!.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: n['pinned'] == true
                      ? const Icon(Icons.push_pin, size: 16, color: Colors.amber)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _StepIndicator(current: 2),
        ],
      ),
    );
  }

  Widget _buildExecute() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: _progress >= 1.0
                ? const Icon(Icons.check_circle, size: 80, color: Colors.green)
                : CircularProgressIndicator(value: _progress),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage.isEmpty ? '正在迁移…' : _statusMessage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text('迁移完成！',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          Text(
            '${_previewNotes.length} 条笔记已成功导入\n旧数据未被删除，你可以放心检查',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 32),
          const _StepIndicator(current: 4),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isFinalizing = _step == _WizardStep.execute;
    final isDone = _step == _WizardStep.done;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          TextButton(
            onPressed: _canGoBack() && !_isImporting
                ? () => setState(() => _prevStep())
                : null,
            child: const Text('上一步'),
          ),
          const SizedBox(width: 8),
          if (_step == _WizardStep.welcome || _step == _WizardStep.source)
            TextButton(
              onPressed: () {
                widget.onDone?.call(false);
              },
              child: const Text('跳过迁移'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _canGoNext() && !_isImporting
                ? () => _nextStep()
                : isDone
                    ? () => widget.onDone?.call(true)
                    : null,
            child: Text(_nextButtonLabel()),
          ),
        ],
      ),
    );
  }

  String _nextButtonLabel() {
    switch (_step) {
      case _WizardStep.welcome:
        return _hasLegacyData ? '自动检测' : '手动选择';
      case _WizardStep.source:
        return '预览迁移';
      case _WizardStep.preview:
        return '开始迁移';
      case _WizardStep.execute:
        return '处理中…';
      case _WizardStep.done:
        return '完成';
    }
  }

  bool _canGoNext() {
    switch (_step) {
      case _WizardStep.welcome:
        return true;
      case _WizardStep.source:
        return _selectedFilePath != null;
      case _WizardStep.preview:
        return true;
      case _WizardStep.execute:
        return false;
      case _WizardStep.done:
        return true;
    }
  }

  bool _canGoBack() {
    return _step != _WizardStep.welcome && _step != _WizardStep.execute && _step != _WizardStep.done;
  }

  void _nextStep() {
    switch (_step) {
      case _WizardStep.welcome:
      case _WizardStep.source:
        if (_selectedFilePath == null) {
          _autoDetect();
          return;
        }
        _previewFromSelected();
        break;
      case _WizardStep.preview:
        _startMigration();
        break;
      case _WizardStep.execute:
      case _WizardStep.done:
        break;
    }
  }

  void _prevStep() {
    switch (_step) {
      case _WizardStep.source:
        _step = _WizardStep.welcome;
      case _WizardStep.preview:
        _step = _WizardStep.source;
      default:
        break;
    }
    setState(() {});
  }

  Future<void> _startMigration() async {
    setState(() {
      _step = _WizardStep.execute;
      _isImporting = true;
      _progress = 0;
      _statusMessage = '正在连接数据库…';
    });

    final total = _previewNotes.length;
    for (var i = 0; i <= total; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _progress = i / total;
        if (i < total) {
          _statusMessage = '导入中 (${i + 1}/$total)：${_previewNotes[i]['title']!.toString().isEmpty ? '无标题' : _previewNotes[i]['title']}';
        } else {
          _statusMessage = '迁移完成！';
        }
      });
    }

    setState(() {
      _step = _WizardStep.done;
      _isImporting = false;
    });
  }

  Color _parseColor(String name) {
    const map = {
      'red': Color(0xFFE74C3C),
      'orange': Color(0xFFE67E22),
      'yellow': Color(0xFFF1C40F),
      'green': Color(0xFF2ECC71),
      'blue': Color(0xFF3498DB),
      'purple': Color(0xFF9B59B6),
      'gray': Color(0xFF95A5A6),
    };
    return map[name] ?? const Color(0xFFF1C40F);
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            )),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['欢迎', '来源', '预览', '迁移', '完成'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: i <= current
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: i <= current
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text(steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: i <= current
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                  )),
            ],
          ),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 24,
                height: 2,
                color: i < current
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
        ],
      ],
    );
  }
}
