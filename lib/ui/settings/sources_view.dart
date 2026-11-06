import 'dart:async';

import 'package:flutter/material.dart';

import '../../local_store.dart';
import '../../models.dart';
import '../app_scope.dart';
import '../shell/app_shell.dart';
import '../widgets/focus_ring.dart';
import '../widgets/group_card.dart';
import 'custom_sources_view.dart';
import 'settings_rows.dart';

/// 站源管理：内置源的显示开关 + 自定义源（MacCMS 站点 / XBPQ 规则）管理入口。
///
/// 源显示属于「谁用谁看」的本机偏好，所有用户都能调整，不再要求管理员身份。
/// 每台设备、每个用户各自保存自己的开关状态，互不影响。
class SourcesView extends StatefulWidget {
  const SourcesView({super.key, required this.store});
  final LocalStore store;

  @override
  State<SourcesView> createState() => _SourcesViewState();
}

class _SourcesViewState extends State<SourcesView> {
  var _syncing = false;
  var _synced = false;
  var _testing = false;
  List<Map<String, dynamic>> _speedResults = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) return;
    _synced = true;
    unawaited(_syncCustom());
  }

  /// 自定义源以原生核心为准，这里拉一次同步到本地缓存，
  /// 让源栏、搜索、追剧等处能立刻按真实名称与开关展示。
  Future<void> _syncCustom() async {
    if (_syncing || !mounted) return;
    _syncing = true;
    try {
      final repository = AppScope.of(context).repository;
      await widget.store.syncCustomSources(await repository.customSources());
    } catch (_) {
      // 读取失败不影响内置源开关，页面上自定义源区域会显示为空。
    } finally {
      _syncing = false;
    }
  }

  Future<void> _toggle(String id, bool value, bool downloadable) {
    final repository = AppScope.of(context).repository;
    return saveSetting(context, () async {
      await widget.store.setSourceEnabled(id, value);
      if (!value && downloadable && repository.supportsDownloads) {
        await repository.controlDownloads('pauseSource', id: id);
      }
    });
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「$name」'),
        content: const Text(
          '删除后该站源将从应用内彻底消失、无法恢复（重新编译或清空数据重装才会重新出现）。确定删除吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await saveSetting(context, () => widget.store.deleteSource(id));
  }

  Future<void> _runSpeedTest() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _speedResults = const [];
    });
    try {
      final repository = AppScope.of(context).repository;
      final results = await repository.speedTestSources();
      if (!mounted) return;
      // 已删除的内置源不再出现在测速结果里，避免删了之后第二次测速又冒出来。
      final store = widget.store;
      final visible = results
          .where((r) => !store.isSourceDeleted((r['id'] as String?) ?? ''))
          .toList();
      setState(() => _speedResults = visible);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speedResults = const []);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _openManager() async {
    final repository = AppScope.of(context).repository;
    await openPage<void>(
      context,
      (_) => CustomSourcesPage(repository: repository, store: widget.store),
    );
    if (mounted) unawaited(_syncCustom());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final customs = store.customSources;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SpeedTestCard(
            testing: _testing,
            results: _speedResults,
            onTest: _runSpeedTest,
          ),
          const SizedBox(height: 12),
          SettingsCard(
            children: [
              for (final site in SourceSite.values)
                if (!store.isSourceDeleted(site.id))
                  _SourceTile(
                    title: site.name,
                    subtitle: site.description,
                    enabled: store.sourceEnabled(site.id),
                    onChanged: (value) => _toggle(site.id, value, true),
                    onDelete: () => _delete(site.id, site.name),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          const _Note(
            '关闭的站源不在发现、搜索、追剧、观看记录和下载中显示，记录保留，重新开启后恢复。正在下载的集会暂停，重新开启后可在下载页继续。',
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '自定义源', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          SettingsCard(
            children: [
              if (customs.isNotEmpty)
                for (final site in customs)
                  _SourceTile(
                    title: site.name,
                    subtitle: site.hasRule
                        ? 'XBPQ 规则 · ${site.base}'
                        : site.base,
                    enabled: store.sourceEnabled(site.id),
                    onChanged: (value) => _toggle(site.id, value, false),
                  ),
              SettingsTile(
                icon: Icons.tune_rounded,
                title: '管理自定义源',
                subtitle: customs.isEmpty
                    ? '添加 MacCMS 站点或 XBPQ 爬虫规则'
                    : '共 ${customs.length} 个 · 新增、编辑、导入导出',
                onTap: _openManager,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Note(
            '自定义源由你自行添加，支持 MacCMS 规范的站点地址或 XBPQ 爬虫规则 JSON。'
            '所有用户都可以添加、修改和删除，内容保存在本机。',
          ),
        ],
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    this.onDelete,
  });
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: TileFocus(
      builder: (focusNode) => ListTile(
        focusNode: focusNode,
        minTileHeight: 68,
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onChanged == null ? null : () => onChanged!(!enabled),
        trailing: ExcludeFocus(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: '删除',
                  onPressed: onDelete,
                ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.6,
      ),
    ),
  );
}

class _SpeedTestCard extends StatelessWidget {
  const _SpeedTestCard({
    required this.testing,
    required this.results,
    required this.onTest,
  });
  final bool testing;
  final List<Map<String, dynamic>> results;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      SettingsTile(
        icon: Icons.speed_rounded,
        title: testing ? '正在测速…' : '站源测速',
        subtitle: results.isEmpty
            ? '检测所有站源的连通性与响应延迟'
            : '共 ${results.length} 个站源 · 绿色快 / 橙色一般 / 红色慢 / 灰色不可用',
        enabled: !testing,
        onTap: testing ? null : onTest,
        trailing: testing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      if (results.isNotEmpty)
        for (final r in results)
          _SpeedRow(
            name: (r['name'] as String?) ?? (r['id'] as String?) ?? '',
            ok: r['ok'] == true,
            latency: (r['latencyMs'] as num?)?.toInt() ?? 0,
          ),
    ],
  );
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({
    required this.name,
    required this.ok,
    required this.latency,
  });
  final String name;
  final bool ok;
  final int latency;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (!ok) {
      label = '不可用';
      color = Colors.grey;
    } else if (latency < 200) {
      label = '$latency ms';
      color = Colors.green;
    } else if (latency < 500) {
      label = '$latency ms';
      color = Colors.orange;
    } else {
      label = '$latency ms';
      color = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
