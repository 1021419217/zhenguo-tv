import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'focus_ring.dart';

/// 顶栏操作按钮：统一为半透明磨砂圆形玻璃按钮（40×40），
/// 白色图标 + 白色细描边。主操作可用 [accent] 反色实心强调，
/// 让一组按钮有主次层次，而不是全部一模一样。
class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 主操作强调：白色实心圆 + 深色图标，仅用于手机顶栏最常用的动作。
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final television = AppScope.of(context).television;
    final emphasize = accent && !television;
    return FocusRing(
      radius: 999,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: television ? 20 : 19),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          padding: EdgeInsets.zero,
          backgroundColor: emphasize
              ? Colors.white
              : television
              ? colors.surfaceContainerHigh
              : Colors.white.withValues(alpha: 0.09),
          foregroundColor: emphasize ? const Color(0xFF111114) : Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: CircleBorder(
            side: BorderSide(
              color: emphasize
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ),
      ),
    );
  }
}
