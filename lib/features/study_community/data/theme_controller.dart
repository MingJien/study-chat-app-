import 'package:flutter/material.dart';

abstract interface class ThemeModeStore {
  Future<ThemeMode?> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}

class InMemoryThemeModeStore implements ThemeModeStore {
  InMemoryThemeModeStore({ThemeMode? initialMode}) : _mode = initialMode;

  ThemeMode? _mode;

  @override
  Future<ThemeMode?> loadThemeMode() async => _mode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _mode = mode;
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeModeStore? store,
    ThemeMode initialMode = ThemeMode.system,
  }) : _store = store ?? InMemoryThemeModeStore(initialMode: initialMode),
       _themeMode = initialMode;

  final ThemeModeStore _store;
  ThemeMode _themeMode;
  bool _isLoaded = false;
  bool _isSaving = false;
  String? _lastError;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String? get lastError => _lastError;

  Future<void> load() async {
    _lastError = null;
    try {
      final saved = await _store.loadThemeMode();
      if (saved != null) {
        _themeMode = saved;
      }
    } catch (_) {
      _lastError = 'Không thể tải cài đặt giao diện.';
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return true;
    final previous = _themeMode;
    _themeMode = mode;
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      await _store.saveThemeMode(mode);
      return true;
    } catch (_) {
      _themeMode = previous;
      _lastError = 'Không thể lưu chế độ giao diện. Vui lòng thử lại.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
