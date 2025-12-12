import 'package:ether_music/api/models/song.dart';

/// LRC 歌词解析器
class LyricsParser {
  /// 解析 LRC 格式歌词
  /// 格式: [mm:ss.xx] 歌词内容
  static List<LyricLine> parse(String lrcContent, {String? translatedContent}) {
    final List<LyricLine> lyrics = [];
    final lines = lrcContent.split('\n');

    // 解析翻译歌词
    final Map<Duration, String> translations = {};
    if (translatedContent != null && translatedContent.isNotEmpty) {
      final transLines = translatedContent.split('\n');
      for (final line in transLines) {
        final parsed = _parseLine(line);
        if (parsed != null) {
          translations[parsed.$1] = parsed.$2;
        }
      }
    }

    // 解析主歌词
    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        lyrics.add(LyricLine(
          time: parsed.$1,
          text: parsed.$2,
          translation: translations[parsed.$1],
        ));
      }
    }

    // 按时间排序
    lyrics.sort((a, b) => a.time.compareTo(b.time));

    return lyrics;
  }

  /// 解析单行歌词
  /// 返回 (时间, 歌词内容)
  static (Duration, String)? _parseLine(String line) {
    // 匹配 [mm:ss.xx] 或 [mm:ss:xx] 格式
    final regex = RegExp(r'\[(\d{2}):(\d{2})[\.:](\d{2,3})\](.*)');
    final match = regex.firstMatch(line);

    if (match == null) return null;

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final millisStr = match.group(3)!;
    // 处理两位数或三位数毫秒
    final millis = millisStr.length == 2
        ? int.parse(millisStr) * 10
        : int.parse(millisStr);
    final text = match.group(4)!.trim();

    if (text.isEmpty) return null;

    return (
      Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
      text,
    );
  }

  /// 使用二分查找找到当前应该高亮的歌词行索引
  /// [position] 当前播放位置
  /// [lyrics] 歌词列表
  /// 返回当前行的索引，如果还没开始则返回 -1
  static int findCurrentIndex(Duration position, List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return -1;

    // 还没到第一句歌词
    if (position < lyrics.first.time) return -1;

    // 已经过了最后一句歌词
    if (position >= lyrics.last.time) return lyrics.length - 1;

    // 二分查找
    int left = 0;
    int right = lyrics.length - 1;

    while (left < right) {
      final mid = (left + right + 1) ~/ 2;
      if (lyrics[mid].time <= position) {
        left = mid;
      } else {
        right = mid - 1;
      }
    }

    return left;
  }

  /// 获取当前歌词行
  static LyricLine? getCurrentLyric(Duration position, List<LyricLine> lyrics) {
    final index = findCurrentIndex(position, lyrics);
    if (index < 0 || index >= lyrics.length) return null;
    return lyrics[index];
  }

  /// 获取当前歌词进度（0.0 - 1.0）
  /// 用于实现逐字动画效果
  static double getCurrentProgress(Duration position, List<LyricLine> lyrics) {
    final currentIndex = findCurrentIndex(position, lyrics);
    if (currentIndex < 0 || currentIndex >= lyrics.length) return 0;

    final currentLine = lyrics[currentIndex];
    final nextLine = currentIndex + 1 < lyrics.length
        ? lyrics[currentIndex + 1]
        : null;

    if (nextLine == null) return 1.0;

    final lineStart = currentLine.time;
    final lineEnd = nextLine.time;
    final lineDuration = lineEnd - lineStart;

    if (lineDuration.inMilliseconds <= 0) return 1.0;

    final elapsed = position - lineStart;
    return (elapsed.inMilliseconds / lineDuration.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// 歌词同步器
class LyricSynchronizer {
  final List<LyricLine> lyrics;
  int _currentIndex = -1;

  LyricSynchronizer(this.lyrics);

  /// 更新当前位置，返回是否需要更新 UI
  bool update(Duration position) {
    final newIndex = LyricsParser.findCurrentIndex(position, lyrics);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      return true;
    }
    return false;
  }

  /// 获取当前歌词行
  LyricLine? get currentLyric =>
      _currentIndex >= 0 && _currentIndex < lyrics.length
          ? lyrics[_currentIndex]
          : null;

  /// 获取当前索引
  int get currentIndex => _currentIndex;

  /// 重置
  void reset() {
    _currentIndex = -1;
  }
}
