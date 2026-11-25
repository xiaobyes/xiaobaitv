import 'tmdb_preferences.dart';

/// 主题模式（持久化用 `dark|light|system`）。
enum AppThemeMode {
  dark('深色'),
  light('浅色'),
  system('跟随系统');

  const AppThemeMode(this.label);

  final String label;

  static AppThemeMode? tryParse(Object? raw) {
    if (raw is! String) return null;
    for (final mode in AppThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }
}

/// 外观偏好：主题 + 壁纸（SET-08 / 主题）。
///
/// 持久化于应用数据目录的 `appearance_preferences.json`。
/// **version 2** 起新增 `themeMode`；读取时兼容 version 1（视为深色），
/// 写入一律为 version 2。
///
/// 壁纸只存**文件名**（形如 `current.jpg`）：图片本体由 `WallpaperStore`
/// 复制到 `wallpaper/` 子目录，因此用户移动 / 删除原图不会让壁纸失效；
/// 「恢复默认」只删副本，**不触碰用户原图**。
///
/// 读取规则：版本 / 顶层结构 / 字段类型非法时抛出 [FormatException]（调用方保留原文件）。
class AppearancePreferences {
  static const int formatVersion = 2;

  /// 可读取的历史版本：1 没有主题字段（按深色处理）。
  static const Set<int> readableVersions = {1, 2};

  /// 文件名允许的字符集：不含路径分隔符，配合 `WallpaperStore` 的目录约束。
  static final RegExp fileNamePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

  /// 当前壁纸副本的文件名（相对 `wallpaper/` 目录）；null 表示使用默认背景。
  final String? wallpaperFileName;

  /// 2.1.x 式「壁纸地址」：http(s) 图片直链或本地图片路径；非空时优先于
  /// [wallpaperFileName]（用户自己那版的换背景做法）。
  final String? wallpaperUrl;

  /// 主题模式；默认深色（与改造前一致）。
  final AppThemeMode themeMode;
  final bool sidebarCollapsed;
  final TmdbPreferences tmdb;

  const AppearancePreferences({
    this.wallpaperFileName,
    this.wallpaperUrl,
    this.themeMode = AppThemeMode.dark,
    this.sidebarCollapsed = false,
    this.tmdb = const TmdbPreferences(),
  });

  /// 未设置壁纸（默认外观）。
  static const AppearancePreferences none = AppearancePreferences();

  bool get hasWallpaper =>
      (wallpaperUrl != null && wallpaperUrl!.isNotEmpty) ||
      (wallpaperFileName != null && wallpaperFileName!.isNotEmpty);

  AppearancePreferences withWallpaperUrl(String? url) => AppearancePreferences(
        wallpaperFileName: wallpaperFileName,
        wallpaperUrl: (url == null || url.trim().isEmpty) ? null : url.trim(),
        themeMode: themeMode,
        sidebarCollapsed: sidebarCollapsed,
        tmdb: tmdb,
      );

  AppearancePreferences withWallpaper(String? fileName) => AppearancePreferences(
        wallpaperFileName: fileName,
        // 换本地图片副本时清掉手填地址，两者只保留一份，避免互相盖掉。
        wallpaperUrl: null,
        tmdb: tmdb,
        themeMode: themeMode,
        sidebarCollapsed: sidebarCollapsed,
      );

  AppearancePreferences withThemeMode(AppThemeMode mode) => AppearancePreferences(
        wallpaperFileName: wallpaperFileName,
        wallpaperUrl: wallpaperUrl,
        themeMode: mode,
        tmdb: tmdb,
        sidebarCollapsed: sidebarCollapsed,
      );

  AppearancePreferences withSidebarCollapsed(bool value) => AppearancePreferences(
        wallpaperFileName: wallpaperFileName,
        wallpaperUrl: wallpaperUrl,
        themeMode: themeMode,
        sidebarCollapsed: value,
        tmdb: tmdb,
      );

  AppearancePreferences withTmdb(TmdbPreferences value) => AppearancePreferences(
        wallpaperFileName: wallpaperFileName,
        wallpaperUrl: wallpaperUrl,
        themeMode: themeMode,
        sidebarCollapsed: sidebarCollapsed,
        tmdb: value,
      );

  static AppearancePreferences fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! int || !readableVersions.contains(version)) {
      throw const FormatException('外观偏好格式无效');
    }
    final rawMode = json['themeMode'];
    if (rawMode != null && rawMode is! String) {
      throw const FormatException('外观偏好格式无效');
    }
    // version 1 没有该字段：按深色处理，保证旧文件无损
    AppThemeMode themeMode;
    if (rawMode == null) {
      themeMode = AppThemeMode.dark;
    } else {
      final parsed = AppThemeMode.tryParse(rawMode);
      if (parsed == null) throw const FormatException('外观偏好格式无效');
      themeMode = parsed;
    }

    final rawCollapsed = json['sidebarCollapsed'];
    if (rawCollapsed != null && rawCollapsed is! bool) {
      throw const FormatException('外观偏好格式无效');
    }
    final sidebarCollapsed = rawCollapsed == true;
    final raw = json['wallpaperFileName'];
    if (raw != null && raw is! String) throw const FormatException('外观偏好格式无效');
    final name = (raw as String?)?.trim() ?? '';
    if (name.isNotEmpty && !fileNamePattern.hasMatch(name)) {
      throw const FormatException('外观偏好格式无效');
    }
    final rawUrl = json['wallpaperUrl'];
    if (rawUrl != null && rawUrl is! String) {
      throw const FormatException('外观偏好格式无效');
    }
    final url = (rawUrl as String?)?.trim() ?? '';
    return AppearancePreferences(
      wallpaperFileName: name.isEmpty ? null : name,
      wallpaperUrl: url.isEmpty ? null : url,
      themeMode: themeMode,
      sidebarCollapsed: sidebarCollapsed,
      tmdb: TmdbPreferences.fromJson(json['tmdb']),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': formatVersion,
        'wallpaperFileName': wallpaperFileName,
        if (wallpaperUrl != null) 'wallpaperUrl': wallpaperUrl,
        'themeMode': themeMode.name,
        'sidebarCollapsed': sidebarCollapsed,
        if (tmdb != const TmdbPreferences()) 'tmdb': tmdb.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is AppearancePreferences &&
      other.wallpaperFileName == wallpaperFileName &&
      other.wallpaperUrl == wallpaperUrl &&
      other.themeMode == themeMode && other.sidebarCollapsed == sidebarCollapsed && other.tmdb == tmdb;

  @override
  int get hashCode =>
      Object.hash(wallpaperFileName, wallpaperUrl, themeMode, sidebarCollapsed, tmdb);

  @override
  String toString() =>
      'AppearancePreferences(wallpaperFileName: $wallpaperFileName, '
      'themeMode: ${themeMode.name}, sidebarCollapsed: $sidebarCollapsed)';
}
