enum ConfigSourceKind { url, file }

/// 配置内容与来源同次保存；sourceKind 为 null 表示粘贴内容。
class ConfigSnapshot {
  final String rawContent;
  final ConfigSourceKind? sourceKind;
  final String? sourceLocation;
  final List<String> depotPath;

  /// 顶层多仓清单解析出的子仓条目（name/url 键值对）；非多仓为空。
  /// 供重启后顶栏「线路」直接在仓内子仓间切换，不必重新拉取顶层清单。
  final List<Map<String, String>> depotEntries;

  ConfigSnapshot({
    required this.rawContent,
    this.sourceKind,
    this.sourceLocation,
    List<String> depotPath = const [],
    List<Map<String, String>> depotEntries = const [],
  })  : depotPath = List.unmodifiable(depotPath),
        depotEntries = List.unmodifiable(depotEntries);

  factory ConfigSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['rawContent'] is! String) {
      throw const FormatException('当前配置快照格式无效');
    }
    final kind = switch (json['sourceKind']) {
      'url' => ConfigSourceKind.url,
      'file' => ConfigSourceKind.file,
      'paste' => null,
      _ => throw const FormatException('当前配置来源类型无效'),
    };
    final location = json['sourceLocation'];
    if (kind != null && (location is! String || location.trim().isEmpty)) {
      throw const FormatException('当前配置来源位置缺失');
    }
    return ConfigSnapshot(
      rawContent: json['rawContent'] as String,
      sourceKind: kind,
      sourceLocation: kind == null ? null : location as String,
      depotPath:
          (json['depotPath'] as List<dynamic>?)?.cast<String>() ?? const [],
      depotEntries: (json['depotEntries'] as List<dynamic>?)
              ?.map((e) {
                final m = e is Map ? e : const {};
                final name = m['name']?.toString() ?? '';
                final url = m['url']?.toString() ?? '';
                return url.isEmpty ? null : {'name': name, 'url': url};
              })
              .whereType<Map<String, String>>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'rawContent': rawContent,
        'sourceKind': sourceKind?.name ?? 'paste',
        if (sourceLocation != null) 'sourceLocation': sourceLocation,
        'depotPath': depotPath,
        if (depotEntries.isNotEmpty) 'depotEntries': depotEntries,
      };
}
