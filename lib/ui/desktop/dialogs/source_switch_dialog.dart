import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// 线路切换弹窗的一个候选项。
class SourceSwitchOption {
  final String title;
  final String subtitle;
  final bool selected;
  final String identity;

  const SourceSwitchOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.identity,
  });
}

/// 顶栏「线路」：切换已保存配置源；多仓源时列出仓内子仓地址。
class SourceSwitchDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SourceSwitchOption> options;
  final ValueChanged<String> onSelect;

  const SourceSwitchDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Dialog(
      backgroundColor: palette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: palette.borderStrong, width: 1),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.raised,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(Icons.swap_horiz_rounded,
                      color: palette.accentInk, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            fontSize: AppType.h2,
                            fontWeight: FontWeight.bold,
                            color: palette.textTitle),
                      ),
                      Text(
                        subtitle,
                        style:
                            TextStyle(fontSize: AppType.body, color: palette.textSub),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: palette.textSub, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: options.isEmpty
                  ? Center(
                      child: Text('暂无可切换的来源',
                          style: TextStyle(color: palette.textDim)))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _OptionTile(option: options[index], onTap: () {
                        Navigator.of(context).pop();
                        onSelect(options[index].identity);
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  final SourceSwitchOption option;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.onTap});

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final option = widget.option;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: option.selected
                ? palette.accentWash
                : _isHovered
                    ? palette.hover
                    : palette.raised,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: option.selected
                  ? palette.accentInk
                  : _isHovered
                      ? palette.borderStrong
                      : palette.pressed,
              width: option.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: option.selected ? palette.accentInk : palette.textDim,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: AppType.label,
                        fontWeight:
                            option.selected ? FontWeight.bold : FontWeight.w500,
                        color: option.selected
                            ? palette.textTitle
                            : palette.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style:
                          TextStyle(fontSize: AppType.caption, color: palette.textSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
