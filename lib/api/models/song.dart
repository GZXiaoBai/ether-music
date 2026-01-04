/// 歌曲数据模型 - 适配 TuneHub API
class Song {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String platform; // netease, qq, kuwo
  final String? coverUrl;
  final String? audioUrl;
  final String? lrcUrl;
  final int duration; // 毫秒

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.platform,
    this.coverUrl,
    this.audioUrl,
    this.lrcUrl,
    this.duration = 0,
  });

  /// 获取艺术家名称（兼容旧代码）
  String get artistNames => artist;

  /// 获取格式化的时长
  String get durationFormatted {
    if (duration <= 0) return '--:--';
    final minutes = (duration / 1000 / 60).floor();
    final seconds = ((duration / 1000) % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 从 TuneHub 聚合搜索结果解析
  factory Song.fromTuneHub(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      platform: json['platform'] as String? ?? 'netease',
      coverUrl: json['pic'] as String?,
      audioUrl: json['url'] as String?,
      lrcUrl: json['lrc'] as String?,
    );
  }

  /// 从旧版网易云 API 解析（兼容性）
  factory Song.fromNetease(Map<String, dynamic> json) {
    final artistList = json['ar'] ?? json['artists'] ?? [];
    final albumData = json['al'] ?? json['album'];
    
    String artistName = '';
    if (artistList is List && artistList.isNotEmpty) {
      artistName = artistList.map((a) => a['name'] as String? ?? '').join(' / ');
    }

    String? coverUrl;
    String albumName = '';
    if (albumData is Map) {
      coverUrl = albumData['picUrl'] as String?;
      albumName = albumData['name'] as String? ?? '';
    }

    return Song(
      id: (json['id'] as int).toString(),
      name: json['name'] as String? ?? '',
      artist: artistName,
      album: albumName,
      platform: 'netease',
      coverUrl: coverUrl,
      duration: json['dt'] ?? json['duration'] ?? 0,
    );
  }

  /// 从本地存储解析
  factory Song.fromJson(Map<String, dynamic> json) {
    // 兼容旧版数据格式
    if (json.containsKey('artists')) {
      return Song.fromNetease(json);
    }
    
    return Song(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      artist: json['artist'] as String? ?? json['artistNames'] as String? ?? '',
      album: json['album'] as String? ?? '',
      platform: json['platform'] as String? ?? 'netease',
      coverUrl: json['coverUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      lrcUrl: json['lrcUrl'] as String?,
      duration: json['duration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'album': album,
    'platform': platform,
    'coverUrl': coverUrl,
    'audioUrl': audioUrl,
    'lrcUrl': lrcUrl,
    'duration': duration,
  };

  Song copyWith({
    String? id,
    String? name,
    String? artist,
    String? album,
    String? platform,
    String? coverUrl,
    String? audioUrl,
    String? lrcUrl,
    int? duration,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      platform: platform ?? this.platform,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      lrcUrl: lrcUrl ?? this.lrcUrl,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          platform == other.platform;

  @override
  int get hashCode => id.hashCode ^ platform.hashCode;
}

/// 排行榜数据模型
class Toplist {
  final String id;
  final String name;
  final String? coverUrl;
  final String? updateFrequency;
  final String source;

  Toplist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.updateFrequency,
    required this.source,
  });

  factory Toplist.fromTuneHub(Map<String, dynamic> json, String source) {
    return Toplist(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      coverUrl: json['pic'] as String?,
      updateFrequency: json['updateFrequency'] as String?,
      source: source,
    );
  }
}

/// 歌单数据模型
class Playlist {
  final String id;
  final String name;
  final String? coverUrl;
  final String? description;
  final int? trackCount;
  final int? playCount;
  final String? creatorName;
  final String source;

  Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.description,
    this.trackCount,
    this.playCount,
    this.creatorName,
    required this.source,
  });

  factory Playlist.fromTuneHub(Map<String, dynamic> json, String source) {
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      coverUrl: json['pic'] ?? json['coverImgUrl'] as String?,
      description: json['description'] as String?,
      trackCount: json['trackCount'] as int?,
      playCount: json['playCount'] as int?,
      creatorName: json['creator']?['nickname'] as String?,
      source: source,
    );
  }

  /// 兼容旧版 fromJson
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      coverUrl: json['coverImgUrl'] ?? json['picUrl'] ?? json['coverUrl'] as String?,
      description: json['description'] as String?,
      trackCount: json['trackCount'] as int?,
      playCount: json['playCount'] ?? json['playcount'] as int?,
      creatorName: json['creator']?['nickname'] as String?,
      source: json['source'] as String? ?? 'netease',
    );
  }
}

/// 歌词行数据模型
class LyricLine {
  final Duration time;
  final String text;
  final String? translation;

  LyricLine({
    required this.time,
    required this.text,
    this.translation,
  });
}

/// 解析 LRC 歌词
List<LyricLine> parseLrc(String lrcContent) {
  final lines = <LyricLine>[];
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
  
  for (final line in lrcContent.split('\n')) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));
      final text = match.group(4)?.trim() ?? '';
      
      if (text.isNotEmpty) {
        lines.add(LyricLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: text,
        ));
      }
    }
  }
  
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}
