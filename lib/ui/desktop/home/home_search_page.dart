import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// 首页「搜索」入口打开的搜索页。
///
/// 2.1.x 观感：整窗半透磨砂遮罩 + 居中大搜索框 + 下方「大家都在搜」热词胶囊。
/// 回车或点热词直接发起搜索；Esc / 点空白 / 右上角关闭退出。
class HomeSearchPage extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClose;
  final List<String> hotWords;

  const HomeSearchPage({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClose,
    this.hotWords = HomeSearchPage.kDefaultHotWords,
  });

  /// 热词兜底表：与站源无关的通用热播片名，点一下就直接搜。
  static const List<String> kDefaultHotWords = [
    '狂飙',
    '庆余年',
    '漫长的季节',
    '流浪地球2',
    '三体',
    '繁花',
    '与凤行',
    '墨雨云间',
    '庆余年 第二季',
    '孤注一掷',
    '封神第一部',
    '消失的她',
  ];

  @override
  State<HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<HomeSearchPage> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final keyword = raw.trim();
    if (keyword.isEmpty) return;
    widget.onSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _CloseSearchIntent(),
      },
      child: Actions(
        actions: {
          _CloseSearchIntent: CallbackAction<_CloseSearchIntent>(
            onInvoke: (_) {
              widget.onClose();
              return null;
            },
          ),
        },
        child: Dialog(
          backgroundColor: palette.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            side: BorderSide(color: palette.border, width: 1),
          ),
          child: Container(
            width: 780,
            height: 580,
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.accentWash,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: palette.accentInk.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: palette.accentInk, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('搜索',
                              style: TextStyle(
                                fontSize: AppType.h2,
                                fontWeight: FontWeight.bold,
                                color: palette.textTitle,
                              )),
                          Text('电影、剧集、综艺、演员…',
                              style: TextStyle(
                                fontSize: AppType.caption,
                                color: palette.textSub,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭搜索',
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close_rounded,
                          size: 22, color: palette.textSub),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _searchField(palette),
                        const SizedBox(height: 22),
                        _hotWords(palette),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField(AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: palette.textSub),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              cursorColor: palette.accentInk,
              style: TextStyle(fontSize: 19, color: palette.textTitle),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '搜索电影、剧集、综艺、演员…',
                hintStyle: TextStyle(fontSize: 17, color: palette.textSub),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: '清空',
                    onPressed: () => widget.controller.clear(),
                    icon: Icon(Icons.cancel_rounded,
                        size: 18, color: palette.textSub),
                  ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentInk,
              foregroundColor: palette.textTitle,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _submit(widget.controller.text),
            child: const Text('搜索', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _hotWords(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 16, color: palette.accentInk),
            const SizedBox(width: 6),
            Text('大家都在搜',
                style: TextStyle(
                  fontSize: AppType.label,
                  fontWeight: FontWeight.w600,
                  color: palette.textBody,
                )),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final word in widget.hotWords)
              _HotWordPill(
                word: word,
                palette: palette,
                onTap: () {
                  widget.controller.text = word;
                  widget.controller.selection =
                      TextSelection.collapsed(offset: word.length);
                  _submit(word);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _HotWordPill extends StatefulWidget {
  final String word;
  final AppPalette palette;
  final VoidCallback onTap;

  const _HotWordPill({
    required this.word,
    required this.palette,
    required this.onTap,
  });

  @override
  State<_HotWordPill> createState() => _HotWordPillState();
}

class _HotWordPillState extends State<_HotWordPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: palette.panel.withValues(alpha: _hover ? 0.45 : 0.30),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
                color: _hover ? palette.accentInk : palette.border,
                width: 1),
          ),
          child: Text(
            widget.word,
            style: TextStyle(
              fontSize: AppType.body,
              color: _hover ? palette.textTitle : palette.textBody,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}
