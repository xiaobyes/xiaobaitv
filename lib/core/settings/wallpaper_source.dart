import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// 壁纸加载状态（设置中心的壁纸卡片用它显示「加载中 / 成功 / 失败原因」）。
class WallpaperStatus {
  final bool loading;
  final String? error;

  /// 这条信息用来区分「接口壁纸 / Bing 每日壁纸 / 用户地址」。
  final String? url;

  /// 附加提示（例如「地址失效，已回退 Bing」），卡片上用提示色显示。
  final String? note;

  const WallpaperStatus(
      {this.loading = false, this.error, this.url, this.note});

  static const idle = WallpaperStatus();

  bool get failed => error != null;
}

/// 全局壁纸状态：壁纸图层写，设置卡片读。
final ValueNotifier<WallpaperStatus> wallpaperStatus =
    ValueNotifier<WallpaperStatus>(WallpaperStatus.idle);

/// 刷新计数：+1 时壁纸图层丢掉缓存重新拉一次（2.1.3 的 ⟳ 按钮）。
final ValueNotifier<int> wallpaperReloadTick = ValueNotifier<int>(0);

final Map<String, Uint8List> _bytesCache = <String, Uint8List>{};

/// 跨天自动换图：游标归零（0 = 当天）+ 丢掉缓存重载。
///
/// 程序开着过夜时由壁纸图层每分钟检测一次日期，跨天后调用这里。
void reloadWallpaperForNewDay() {
  _bingCursor = 0;
  reloadWallpaper();
}

/// 丢掉内存缓存并触发重新加载。
void reloadWallpaper() {
  _bytesCache.clear();
  wallpaperStatus.value = const WallpaperStatus(loading: true);
  wallpaperReloadTick.value = wallpaperReloadTick.value + 1;
}

/// 纯字符集编码：把 `https://中文域名/path` 这类地址规范成 HttpClient 能直接用的 ASCII URL。
/// Dart 的 Uri 不接受非 ASCII 主机名，所以这里自己做 punycode（RFC 3492）。
String normalizeWallpaperUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)
      ? trimmed
      : 'https://$trimmed';
  final match =
      RegExp(r'^(https?)://([^/?#]+)(.*)$', caseSensitive: false).firstMatch(withScheme);
  if (match == null) return withScheme;
  final scheme = match.group(1)!.toLowerCase();
  var authority = match.group(2)!;
  final rest = match.group(3)!;
  // 用户名密码少见，原样保留；主机名与端口分开处理。
  final at = authority.lastIndexOf('@');
  final userInfo = at >= 0 ? authority.substring(0, at + 1) : '';
  final hostPort = at >= 0 ? authority.substring(at + 1) : authority;
  final colon = hostPort.lastIndexOf(':');
  final host = colon >= 0 && !hostPort.contains(']')
      ? hostPort.substring(0, colon)
      : hostPort;
  final port = colon >= 0 && !hostPort.contains(']')
      ? hostPort.substring(colon)
      : '';
  final asciiHost = _asciiHost(host);
  final encodedRest =
      rest.isEmpty ? '/' : Uri.encodeFull(rest).replaceAll('#', '%23');
  return '$scheme://$userInfo$asciiHost$port$encodedRest';
}

String _asciiHost(String host) {
  if (host.isEmpty) return host;
  if (!RegExp(r'[^\x00-\x7F]').hasMatch(host)) return host;
  return host
      .split('.')
      .map((label) => RegExp(r'[^\x00-\x7F]').hasMatch(label)
          ? 'xn--${_punycode(label)}'
          : label)
      .join('.');
}

String _punycode(String label) {
  const base = 36;
  const tMin = 1;
  const tMax = 26;
  const skew = 38;
  const damp = 700;
  const initialBias = 72;
  const initialN = 128;
  final codePoints = label.runes.toList();
  final output = <int>[
    for (final cp in codePoints)
      if (cp < 0x80) cp
  ];
  final basicLength = output.length;
  if (basicLength > 0) output.add(0x2D);
  var n = initialN;
  var delta = 0;
  var bias = initialBias;
  var h = basicLength;
  while (h < codePoints.length) {
    var m = 0x110000;
    for (final cp in codePoints) {
      if (cp >= n && cp < m) m = cp;
    }
    delta += (m - n) * (h + 1);
    n = m;
    for (final cp in codePoints) {
      if (cp < n) delta++;
      if (cp == n) {
        var q = delta;
        for (var k = base;; k += base) {
          final t = k <= bias
              ? tMin
              : (k >= bias + tMax ? tMax : k - bias);
          if (q < t) break;
          output.add(_punyDigit(t + (q - t) % (base - t)));
          q = (q - t) ~/ (base - t);
        }
        output.add(_punyDigit(q));
        bias = _punyAdapt(delta, h + 1, h == basicLength);
        delta = 0;
        h++;
      }
    }
    delta++;
    n++;
  }
  return String.fromCharCodes(output);
}

int _punyDigit(int value) =>
    value < 26 ? value + 0x61 : value - 26 + 0x30;

int _punyAdapt(int delta, int numPoints, bool firstTime) {
  const base = 36;
  const tMin = 1;
  const tMax = 26;
  const skew = 38;
  const damp = 700;
  var d = firstTime ? delta ~/ damp : delta ~/ 2;
  d += d ~/ numPoints;
  var k = 0;
  while (d > ((base - tMin) * tMax) ~/ 2) {
    d = d ~/ (base - tMin);
    k += base;
  }
  return k + (((base - tMin + 1) * d) ~/ (d + skew));
}

class _Fetched {
  final Uint8List bytes;
  final String? contentType;
  const _Fetched(this.bytes, this.contentType);
}

String _origin(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final buffer = StringBuffer('${uri.scheme}://${uri.host}');
  if (uri.hasPort) buffer.write(':${uri.port}');
  buffer.write('/');
  return buffer.toString();
}

Future<_Fetched> _get(String url, {String? referer}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12)
    ..userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/131.0.0.0 Safari/537.36';
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(
        const Duration(seconds: 15));
    request.followRedirects = true;
    request.headers.set(HttpHeaders.acceptHeader,
        'image/avif,image/webp,image/png,image/jpeg,image/*,*/*;q=0.8');
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'zh-CN,zh;q=0.9');
    request.headers.set(HttpHeaders.refererHeader, referer ?? _origin(url));
    final response = await request.close().timeout(const Duration(seconds: 20));
    final bytes = await consolidateHttpClientResponseBytes(response);
    final type = response.headers.contentType?.mimeType;
    if (response.statusCode >= 400) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    return _Fetched(bytes, type);
  } finally {
    client.close(force: true);
  }
}

/// 从 HTML / JSON 文本里挑一张图（很多「壁纸站」根地址返回的是网页）。
String? _firstImageInText(String text) {
  final patterns = <RegExp>[
    RegExp(r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)''',
        caseSensitive: false),
    RegExp(r'''["']?(?:img|image|url|src)["']?\s*[:=]\s*["']((?:https?:)?//[^"']+\.(?:jpe?g|png|webp|gif|avif)[^"']*)''',
        caseSensitive: false),
    RegExp(r'''(https?:)?//[^\s"'<>()]+\.(?:jpe?g|png|webp|gif|avif)''',
        caseSensitive: false),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match == null) continue;
    var value = match.groupCount >= 1 ? (match.group(1) ?? '') : match.group(0)!;
    value = value.trim();
    if (value.isEmpty) continue;
    if (value.startsWith('//')) value = 'https:$value';
    if (value.startsWith('http')) return value;
  }
  return null;
}

/// 拉取壁纸字节（带 UA / Referer，绕开常见防盗链）。
Future<Uint8List> fetchWallpaperBytes(String raw) async {
  final url = normalizeWallpaperUrl(raw);
  final cached = _bytesCache[url];
  if (cached != null) {
    wallpaperStatus.value = WallpaperStatus(url: url);
    return cached;
  }
  wallpaperStatus.value = WallpaperStatus(loading: true, url: url);
  try {
    var fetched = await _get(url);
    var mime = fetched.contentType;
    var bytes = fetched.bytes;
    if (mime == null || !mime.startsWith('image')) {
      // 不是图片：当作网页，从里面找第一张图再拉一次。
      final text = utf8.decode(bytes, allowMalformed: true);
      final imageUrl = _firstImageInText(text);
      if (imageUrl == null) {
        throw const FormatException('该地址返回的不是图片（可能是网页或接口）');
      }
      fetched = await _get(normalizeWallpaperUrl(imageUrl), referer: url);
      mime = fetched.contentType;
      bytes = fetched.bytes;
      if (mime != null && !mime.startsWith('image')) {
        throw const FormatException('壁纸地址里没有可用的图片');
      }
    }
    _bytesCache[url] = bytes;
    wallpaperStatus.value = WallpaperStatus(url: url);
    return bytes;
  } on TimeoutException {
    wallpaperStatus.value = WallpaperStatus(
        error: '连接超时，检查网络或换个地址', url: url);
    rethrow;
  } on SocketException catch (error) {
    wallpaperStatus.value = WallpaperStatus(
        error: '域名解析或连接失败（${error.osError?.message ?? '网络不可达'}）',
        url: url);
    rethrow;
  } on HttpException catch (error) {
    wallpaperStatus.value =
        WallpaperStatus(error: '服务器返回 ${error.message}', url: url);
    rethrow;
  } on FormatException catch (error) {
    wallpaperStatus.value =
        WallpaperStatus(error: error.message, url: url);
    rethrow;
  } catch (error) {
    wallpaperStatus.value =
        WallpaperStatus(error: '壁纸加载失败：$error', url: url);
    rethrow;
  }
}

/// Bing 每日壁纸（`HPImageArchive.aspx`）：随机取近 8 天里的一张，
/// 所以点「刷新」能换一张，而不是永远同一个 1920×1080。
/// 作为兜底来源：用户地址 / 接口壁纸都没配、或者配的地址失效时用它。
/// Bing 归档游标：0 = 今天，1 = 昨天……点一次「刷新」就往后挪一张。
int _bingCursor = 0;

Future<Uint8List> fetchBingWallpaperBytes({String? note}) async {
  // 缓存键带日期：跨天后再拉一次不会命中昨天的字节。
  final now = DateTime.now();
  final cacheKey = 'bing-daily-${now.year}-${now.month}-${now.day}';
  final cached = _bytesCache[cacheKey];
  if (cached != null) {
    wallpaperStatus.value = WallpaperStatus(url: 'Bing 每日壁纸', note: note);
    return cached;
  }
  wallpaperStatus.value = WallpaperStatus(loading: true, url: 'Bing 每日壁纸');
  try {
    final idx = _bingCursor;
    _bingCursor = (_bingCursor + 1) % 8;
    final metaUrl =
        'https://www.bing.com/HPImageArchive.aspx?format=js&idx=$idx&n=1&mkt=zh-CN';
    final meta = await _get(metaUrl);
    final text = utf8.decode(meta.bytes, allowMalformed: true);
    final match = RegExp(r'"urlbase":"([^"]+)"').firstMatch(text);
    if (match == null) {
      throw const FormatException('Bing 接口没有返回图片信息');
    }
    final base = match.group(1)!.replaceAll(r'\u0026', '&');
    final imageUrl = 'https://www.bing.com${base}_1920x1080.jpg';
    final image = await _get(imageUrl);
    final bytes = image.bytes;
    _bytesCache[cacheKey] = bytes;
    wallpaperStatus.value = WallpaperStatus(url: 'Bing 每日壁纸', note: note);
    return bytes;
  } on Exception catch (error) {
    wallpaperStatus.value =
        WallpaperStatus(error: 'Bing 壁纸获取失败：$error', url: 'Bing 每日壁纸');
    rethrow;
  }
}
