import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'bar_button.dart';
import 'page_header.dart';
import 'search_field.dart';

class SourceBar extends StatelessWidget {
  const SourceBar({
    super.key,
    required this.source,
    required this.onSwitchSource,
    required this.onOpenSearch,
    required this.onSearchSubmitted,
    this.searchController,
    this.televisionLeading,
    this.actions = const [],
  });
  final String source;
  final void Function(BuildContext anchor) onSwitchSource;
  final VoidCallback onOpenSearch;
  final ValueChanged<String> onSearchSubmitted;
  final TextEditingController? searchController;
  final Widget? televisionLeading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final form = AppScope.formFactorOf(context);
    final hint = '在 $source 中搜索';
    final switcher = Builder(
      builder: (anchor) => BarButton(
        icon: Icons.public_rounded,
        tooltip: '切换站源',
        onPressed: () => onSwitchSource(anchor),
      ),
    );
    final search = BarButton(
      icon: Icons.search_rounded,
      tooltip: hint,
      onPressed: onOpenSearch,
      accent: true,
    );
    // 站源名与换源合为一体：整颗胶囊都可点击，不用再去右上角找地球图标。
    final title = _SourceSwitcher(
      source: source,
      onSwitchSource: onSwitchSource,
    );
    return switch (form) {
      FormFactor.phone => PageHeader(
        title: source,
        titleChild: title,
        actions: [
          _actionRow([...actions, search]),
        ],
      ),
      FormFactor.pad || FormFactor.window => PageHeader(
        title: source,
        titleChild: title,
        actions: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width >= 900 ? 320 : 240,
            child: SearchField(
              hint: hint,
              controller: searchController,
              onSubmitted: onSearchSubmitted,
            ),
          ),
          const SizedBox(width: 4),
          ...actions,
        ],
      ),
      // 电视端保留独立的地球按钮，适配遥控器焦点遍历。
      FormFactor.television => SizedBox(
        height: 48,
        child: Row(
          spacing: 10,
          children: [
            ?televisionLeading,
            const Spacer(),
            Text(
              source,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            switcher,
            search,
            ...actions,
          ],
        ),
      ),
    };
  }

  /// 操作组等距 8px 排列，主操作（搜索）在最右且反色强调。
  Widget _actionRow(List<Widget?> items) {
    final children = items.whereType<Widget>().toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    );
  }
}

/// 站源切换胶囊：主题色地球徽标 + 当前站源名 + 下拉箭头，
/// 磨砂玻璃底与细白描边，和右侧反色搜索钮形成「一虚一实」的呼应。
/// 整块都可点击，点开即为全部站源列表，换源一步到位。
class _SourceSwitcher extends StatelessWidget {
  const _SourceSwitcher({required this.source, required this.onSwitchSource});
  final String source;
  final void Function(BuildContext anchor) onSwitchSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    // 深色用白色磨砂玻璃，浅色换成淡墨色玻璃，保证两种主题下都清晰。
    final ink = dark ? Colors.white : colors.onSurface;
    final glass = dark ? Colors.white : colors.onSurface;
    return Builder(
      builder: (anchor) => Tooltip(
        message: '切换站源',
        child: Semantics(
          button: true,
          label: '当前站源 $source，点击切换',
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSwitchSource(anchor),
              borderRadius: BorderRadius.circular(22),
              splashColor: glass.withValues(alpha: 0.10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glass.withValues(alpha: dark ? 0.12 : 0.07),
                      glass.withValues(alpha: dark ? 0.05 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: glass.withValues(alpha: dark ? 0.16 : 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.22),
                      ),
                      child: Icon(
                        Icons.public_rounded,
                        size: 17,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
