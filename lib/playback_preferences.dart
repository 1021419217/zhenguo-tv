import 'video_enhancement_preferences.dart';

const playbackSpeeds = [.5, .75, 1.0, 1.25, 1.5, 2.0, 3.0];

/// 长按播放画面时的临时倍速可选档位。
const playbackBoostSpeeds = [2.0, 2.5, 3.0];

enum TelevisionDecoder { optimized, hardware, software }

class PlaybackPreferences {
  const PlaybackPreferences({
    this.speed = 1,
    this.boostSpeed = 2,
    this.quality = 0,
    this.autoAdvance = true,
    this.danmaku = true,
    this.preload = true,
    this.adBlock = true,
    this.enhancement = const VideoEnhancementPreferences(),
    this.televisionDecoder = TelevisionDecoder.optimized,
  });

  final double speed;

  /// 长按播放画面时的临时倍速（松手恢复，可锁定）。
  final double boostSpeed;
  final int quality;
  final bool autoAdvance;
  final bool danmaku;
  final bool preload;

  /// 解析时是否尝试跳过源站片头广告；关闭后直接播放原始视频流。
  final bool adBlock;
  final VideoEnhancementPreferences enhancement;
  final TelevisionDecoder televisionDecoder;

  PlaybackPreferences copyWith({
    double? speed,
    double? boostSpeed,
    int? quality,
    bool? autoAdvance,
    bool? danmaku,
    bool? preload,
    bool? adBlock,
    VideoEnhancementPreferences? enhancement,
    TelevisionDecoder? televisionDecoder,
  }) => PlaybackPreferences(
    speed: speed ?? this.speed,
    boostSpeed: boostSpeed ?? this.boostSpeed,
    quality: quality ?? this.quality,
    autoAdvance: autoAdvance ?? this.autoAdvance,
    danmaku: danmaku ?? this.danmaku,
    preload: preload ?? this.preload,
    adBlock: adBlock ?? this.adBlock,
    enhancement: enhancement ?? this.enhancement,
    televisionDecoder: televisionDecoder ?? this.televisionDecoder,
  );

  Map<String, dynamic> toJson() => {
    'speed': speed,
    'boostSpeed': boostSpeed,
    'quality': quality,
    'autoAdvance': autoAdvance,
    'danmaku': danmaku,
    'preload': preload,
    'adBlock': adBlock,
    'enhancement': enhancement.toJson(),
    'televisionDecoder': televisionDecoder.name,
  };

  factory PlaybackPreferences.fromJson(Map<String, dynamic> value) {
    final speed = (value['speed'] as num? ?? 1).toDouble();
    final rawBoostSpeed = (value['boostSpeed'] as num? ?? 2).toDouble();
    final quality = value['quality'] as int? ?? 0;
    final autoAdvance = value['autoAdvance'] as bool? ?? true;
    final danmaku = value['danmaku'] as bool? ?? true;
    final preload = value['preload'] as bool? ?? true;
    final adBlock = value['adBlock'] as bool? ?? true;
    if (!playbackSpeeds.contains(speed) || quality < 0 || quality > 4320) {
      throw const FormatException('播放偏好无效');
    }
    final boostSpeed = playbackBoostSpeeds.contains(rawBoostSpeed)
        ? rawBoostSpeed
        : 2.0;
    return PlaybackPreferences(
      speed: speed,
      boostSpeed: boostSpeed,
      quality: quality,
      autoAdvance: autoAdvance,
      danmaku: danmaku,
      preload: preload,
      adBlock: adBlock,
      enhancement: VideoEnhancementPreferences.fromJson(value['enhancement']),
      televisionDecoder:
          TelevisionDecoder.values.asNameMap()[value['televisionDecoder']] ??
          TelevisionDecoder.optimized,
    );
  }
}
