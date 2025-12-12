/// 歌曲数据模型
class Song {
  final int id;
  final String name;
  final List<Artist> artists;
  final Album? album;
  final int duration; // 毫秒
  final String? coverUrl;
  final String? url;
  final bool isVip;

  Song({
    required this.id,
    required this.name,
    required this.artists,
    this.album,
    required this.duration,
    this.coverUrl,
    this.url,
    this.isVip = false,
  });

  /// 获取艺术家名称（多个用 / 分隔）
  String get artistNames => artists.map((a) => a.name).join(' / ');

  /// 获取格式化的时长
  String get durationFormatted {
    final minutes = (duration / 1000 / 60).floor();
    final seconds = ((duration / 1000) % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    // 处理不同 API 返回格式
    final artistList = json['ar'] ?? json['artists'] ?? [];
    final albumData = json['al'] ?? json['album'];

    // 本地存储格式使用 coverUrl 直接存储
    String? coverUrl = json['coverUrl'] as String?;
    if (coverUrl == null && albumData != null) {
      coverUrl = albumData['picUrl'] ?? albumData['coverUrl'] as String?;
    }

    return Song(
      id: json['id'] as int,
      name: json['name'] as String,
      artists: (artistList as List)
          .map((a) => Artist.fromJson(a as Map<String, dynamic>))
          .toList(),
      album: albumData != null
          ? Album.fromJson(albumData as Map<String, dynamic>)
          : null,
      duration: json['dt'] ?? json['duration'] ?? 0,
      coverUrl: coverUrl,
      url: json['url'] as String?,
      isVip: json['isVip'] == true || (json['fee'] == 1) || (json['privilege']?['fee'] == 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'artists': artists.map((a) => a.toJson()).toList(),
        'album': album?.toJson(),
        'duration': duration,
        'coverUrl': coverUrl,
        'url': url,
        'isVip': isVip,
      };

  Song copyWith({
    int? id,
    String? name,
    List<Artist>? artists,
    Album? album,
    int? duration,
    String? coverUrl,
    String? url,
    bool? isVip,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      url: url ?? this.url,
      isVip: isVip ?? this.isVip,
    );
  }
}

/// 艺术家数据模型
class Artist {
  final int id;
  final String name;
  final String? avatarUrl;
  final int? albumCount;
  final int? musicCount;

  Artist({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.albumCount,
    this.musicCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['picUrl'] ?? json['img1v1Url'] as String?,
      albumCount: json['albumSize'] as int?,
      musicCount: json['musicSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'albumCount': albumCount,
        'musicCount': musicCount,
      };
}

/// 专辑数据模型
class Album {
  final int id;
  final String name;
  final String? coverUrl;
  final Artist? artist;
  final int? publishTime;
  final int? songCount;

  Album({
    required this.id,
    required this.name,
    this.coverUrl,
    this.artist,
    this.publishTime,
    this.songCount,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final artistData = json['artist'] ?? json['artists']?.first;

    return Album(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['picUrl'] ?? json['blurPicUrl'] as String?,
      artist: artistData != null
          ? Artist.fromJson(artistData as Map<String, dynamic>)
          : null,
      publishTime: json['publishTime'] as int?,
      songCount: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coverUrl': coverUrl,
        'artist': artist?.toJson(),
        'publishTime': publishTime,
        'songCount': songCount,
      };
}

/// 歌单数据模型
class Playlist {
  final int id;
  final String name;
  final String? coverUrl;
  final String? description;
  final int? trackCount;
  final int? playCount;
  final String? creatorName;
  final String? creatorAvatarUrl;

  Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.description,
    this.trackCount,
    this.playCount,
    this.creatorName,
    this.creatorAvatarUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;

    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['coverImgUrl'] ?? json['picUrl'] as String?,
      description: json['description'] as String?,
      trackCount: json['trackCount'] as int?,
      playCount: json['playCount'] ?? json['playcount'] as int?,
      creatorName: creator?['nickname'] as String?,
      creatorAvatarUrl: creator?['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coverUrl': coverUrl,
        'description': description,
        'trackCount': trackCount,
        'playCount': playCount,
        'creatorName': creatorName,
        'creatorAvatarUrl': creatorAvatarUrl,
      };
}

/// 歌词数据模型
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
