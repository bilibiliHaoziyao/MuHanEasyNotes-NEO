import 'package:flutter/material.dart';

/// 共享笔记卡片组件（各平台可定制）
class NoteCard extends StatelessWidget {
  final String title;
  final String content;
  final String color;
  final bool pinned;
  final DateTime updatedAt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.pinned,
    required this.updatedAt,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorValue = _parseColor(color);
    return Card(
      elevation: pinned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorValue.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? '无标题' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (pinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                content.isEmpty ? '（空）' : content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}

/// 空状态占位
class EmptyState extends StatelessWidget {
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 颜色选择器
class ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const ColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      ('red', Color(0xFFE74C3C)),
      ('orange', Color(0xFFE67E22)),
      ('yellow', Color(0xFFF1C40F)),
      ('green', Color(0xFF2ECC71)),
      ('blue', Color(0xFF3498DB)),
      ('purple', Color(0xFF9B59B6)),
      ('gray', Color(0xFF95A5A6)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors
          .map((c) => InkWell(
                onTap: () => onChanged(c.$1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == c.$1
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected == c.$1
                      ? const Icon(Icons.check,
                          size: 18, color: Colors.white)
                      : null,
                ),
              ))
          .toList(),
    );
  }
}
