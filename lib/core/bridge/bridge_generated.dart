// 这个文件是 flutter_rust_bridge_codegen generate 的产物占位
// 实际运行前请执行: dart run flutter_rust_bridge_codegen generate

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// Rust 端暴露的数据类占位
class Note {
  final String id;
  final String title;
  final String content;
  final String color;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      color: json['color'] as String? ?? 'yellow',
      pinned: json['pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'color': color,
        'pinned': pinned,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}

class AppSettings {
  final double uiScale;
  final double fontScale;
  final int autosaveDebounceMs;
  final bool? darkMode;
  final String? passwordHash;
  final int autoLockSeconds;
  final String? webdavUrl;
  final String? webdavUsername;
  final String? webdavPassword;
  final bool webdavSyncEnabled;
  final String language;

  const AppSettings({
    this.uiScale = 1.0,
    this.fontScale = 1.0,
    this.autosaveDebounceMs = 1200,
    this.darkMode,
    this.passwordHash,
    this.autoLockSeconds = 300,
    this.webdavUrl,
    this.webdavUsername,
    this.webdavPassword,
    this.webdavSyncEnabled = false,
    this.language = 'zh_CN',
  });
}

class BackupFile {
  final String app;
  final String version;
  final String exportedAt;
  final List<Note> notes;
  final List<Attachment> attachments;
  final AppSettings settings;

  const BackupFile({
    this.app = 'MuHanEasyNotes NEO',
    this.version = '2.0.0',
    this.exportedAt = '',
    this.notes = const [],
    this.attachments = const [],
    this.settings = const AppSettings(),
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    return BackupFile(
      app: json['app'] as String? ?? '',
      version: json['version'] as String? ?? '',
      exportedAt: json['exported_at'] as String? ?? '',
      notes: (json['notes'] as List? ?? [])
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List? ?? [])
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: AppSettings(),
    );
  }
}

class Attachment {
  final String id;
  final String noteId;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String? ?? '',
        noteId: json['note_id'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
        mimeType: json['mime_type'] as String? ?? '',
        fileSize: json['file_size'] as int? ?? 0,
        createdAt: DateTime.now(),
      );
}

/// Rust 侧 API 调用的 dart 封装（通过 FFI）
/// flutter_rust_bridge generate 后会自动产出类型安全的 API
class RustBridge {
  RustBridge._();

  static Future<String> appVersion() async => '2.0.0';

  static Future<String> autoTitle(String content) async {
    // 实际实现由 flutter_rust_bridge 提供
    if (content.trim().isEmpty) return '无标题';
    final trimmed = content.trim();
    const stopChars = ['\n', '。', '.', '，', ',', '！', '!', '？', '?'];
    for (var i = 0; i < trimmed.length && i < 15; i++) {
      if (stopChars.contains(trimmed[i])) {
        return trimmed.substring(0, i).trim();
      }
    }
    return trimmed.length > 15 ? trimmed.substring(0, 15) : trimmed;
  }

  static Future<bool> initialize() async => true;
}
