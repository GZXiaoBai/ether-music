import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';

/// Android/iOS 后台音频服务处理器
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService = MusicService();
  
  List<Song> _queue = [];
  int _currentIndex = 0;

  AudioPlayerHandler() {
    // 监听播放状态变化
    _player.playbackEventStream.listen(_broadcastState);
    
    // 监听播放完成
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  /// 设置播放队列
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = songs;
    _currentIndex = startIndex;
    
    // 更新队列
    queue.add(_queue.map((s) => _songToMediaItem(s)).toList());
    
    // 播放指定歌曲
    await _playCurrentSong();
  }

  MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.id.toString(),
      album: song.album?.name ?? '',
      title: song.name,
      artist: song.artistNames,
      artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
      duration: Duration(milliseconds: song.duration),
      extras: {'songId': song.id},
    );
  }

  Future<void> _playCurrentSong() async {
    if (_queue.isEmpty || _currentIndex >= _queue.length) return;
    
    final song = _queue[_currentIndex];
    
    // 更新当前媒体项
    mediaItem.add(_songToMediaItem(song));
    
    // 获取歌曲 URL
    final url = await _musicService.getSongUrl(song.id);
    if (url == null || url.isEmpty) {
      // 无法获取 URL，跳到下一首
      await skipToNext();
      return;
    }
    
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      await skipToNext();
    }
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _playCurrentSong();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _playCurrentSong();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrentSong();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// 获取当前播放器实例
  AudioPlayer get player => _player;
  
  /// 获取当前歌曲
  Song? get currentSong => _queue.isNotEmpty ? _queue[_currentIndex] : null;
  
  /// 获取队列
  List<Song> get songQueue => _queue;
  
  /// 获取当前索引
  int get currentIndex => _currentIndex;
}

/// 初始化音频服务（用于移动端后台播放）
Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ether.music.channel.audio',
      androidNotificationChannelName: 'Ether 音乐播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
}
