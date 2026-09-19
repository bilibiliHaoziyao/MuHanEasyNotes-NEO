import 'package:flutter/foundation.dart';
import '../core/bridge/bridge.dart';

/// 笔记状态管理 Provider
class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  Note? _selected;
  Note? get selected => _selected;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadNotes({
    String? query,
    bool includeDeleted = false,
    bool pinnedOnly = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // flutter_rust_bridge 生成的 API
      // _notes = await RustBridge.listNotes(query: query, ...);
      _notes = []; // 占位
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note?> getNote(String id) async {
    _selected = null;
    notifyListeners();
    try {
      // _selected = await RustBridge.getNote(id: id);
    } catch (e) {
      _error = e.toString();
    }
    return _selected;
  }

  Future<void> createNote({
    required String title,
    required String content,
    String? color,
  }) async {
    try {
      // final note = await RustBridge.createNote(title, content, color);
      // _notes.insert(0, note);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
    String? color,
    bool pinned = false,
  }) async {
    try {
      // final updated = await RustBridge.updateNote(id, title, content, color, pinned);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id, {bool permanent = false}) async {
    try {
      // await RustBridge.deleteNote(id, permanent);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restoreNote(String id) async {
    try {
      // await RustBridge.restoreNote(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
