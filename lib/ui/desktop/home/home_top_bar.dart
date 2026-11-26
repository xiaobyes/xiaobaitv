import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_icon_assets.dart';
import '../../theme/app_palette.dart';

/// 点播主界面顶部常驻栏：LOGO（点击回首页）+ 一排与 LOGO 同尺寸的
/// 功能图标按钮 + 右侧站源胶囊与时钟。
///
/// 仅在点播主界面常驻；播放器 / 直播全屏时不挂载本栏。
class HomeTopBar extends StatefulWidget {
  final String? siteName;
  final VoidCallback? onHomeTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onLiveTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onConfigTap;
  final VoidCallback? onSiteTap;
  final VoidCallback? onLineTap;
  final VoidCallback? onFavTap;
  final VoidCallback? onWallpaperTap;
  final VoidCallback? onThemeTap;
  final VoidCallback? onSettingsTap;

  const HomeTopBar({
    super.key,
    this.siteName,
    this.onHomeTap,
    this.onHistoryTap,
    this.onLiveTap,
    this.onSearchTap,
    this.onConfigTap,
    this.onSiteTap,
    this.onLineTap,
    this.onFavTap,
    this.onWallpaperTap,
    this.onThemeTap,
    this.onSettingsTap,
  });

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 10, 36, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LogoButton(
            palette: palette,
            onTap: widget.onHomeTap,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolIconButton(
                    icon: Icons.home_rounded,
                    label: '首页',
                    palette: palette,
                    onTap: widget.onHomeTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.live_tv_rounded,
                    label: '直播',
                    palette: palette,
                    onTap: widget.onLiveTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.history_rounded,
                    label: '历史',
                    palette: palette,
                    onTap: widget.onHistoryTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.search_rounded,
                    label: '搜索',
                    palette: palette,
                    onTap: widget.onSearchTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.link_rounded,
                    label: '配置',
                    palette: palette,
                    onTap: widget.onConfigTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.swap_horiz_rounded,
                    label: '线路',
                    palette: palette,
                    onTap: widget.onLineTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.favorite_border_rounded,
                    label: '收藏',
                    palette: palette,
                    onTap: widget.onFavTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.image_rounded,
                    label: '壁纸',
                    palette: palette,
                    onTap: widget.onWallpaperTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.brightness_4_rounded,
                    label: '明暗',
                    palette: palette,
                    onTap: widget.onThemeTap,
                  ),
                  _ToolIconButton(
                    icon: Icons.settings_rounded,
                    label: '设置',
                    palette: palette,
                    onTap: widget.onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          _SitePill(
            palette: palette,
            siteName: widget.siteName,
            onTap: widget.onSiteTap,
          ),
          const SizedBox(width: 14),
          Text('$hh:$mm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: palette.textTitle,
              )),
        ],
      ),
    );
  }
}

/// LOGO 按钮：50×50 圆角应用图标，点击回首页。
class _LogoButton extends StatelessWidget {
  final AppPalette palette;
  final VoidCallback? onTap;

  const _LogoButton({required this.palette, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(appIconAsset,
                width: 50,
                height: 50,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true),
          ),
        ),
      ),
    );
  }
}

/// 功能图标按钮：50×50（与 LOGO 同尺寸），图标在上、悬停提色，文字走 Tooltip。
class _ToolIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _ToolIconButton({
    required this.icon,
    required this.label,
    required this.palette,
    this.onTap,
  });

  @override
  State<_ToolIconButton> createState() => _ToolIconButtonState();
}

class _ToolIconButtonState extends State<_ToolIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _hover
                    ? palette.accentInk.withValues(alpha: 0.18)
                    : palette.panel.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _hover ? palette.accentInk : palette.border,
                ),
              ),
              child: Icon(widget.icon, size: 24, color: palette.accentInk),
            ),
          ),
        ),
      ),
    );
  }
}

/// 站源胶囊：`⟳ 站点名`，窄窗口省略。
class _SitePill extends StatefulWidget {
  final AppPalette palette;
  final String? siteName;
  final VoidCallback? onTap;

  const _SitePill({required this.palette, this.siteName, this.onTap});

  @override
  State<_SitePill> createState() => _SitePillState();
}

class _SitePillState extends State<_SitePill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final name = (widget.siteName?.trim().isEmpty ?? true)
        ? '选择站源'
        : widget.siteName!.trim();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: _hover
                ? palette.accentInk.withValues(alpha: 0.20)
                : palette.raised.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hover
                  ? palette.accentInk
                  : palette.border.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded,
                  size: 16, color: palette.accentInk),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
