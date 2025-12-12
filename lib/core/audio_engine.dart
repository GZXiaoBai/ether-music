import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';

/// 播放模式
enum PlayMode {
  sequence, // 顺序播放
  loop, // 列表循环
  single, // 单曲循环
  shuffle, // 随机播放
}

/// 音频播放引擎
class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();
  factory AudioEngine() => _instance;

  late final AudioPlayer _player;
  final MusicService _musicService = MusicService();

  // 播放队列
  final List<Song> _queue = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequence;

  // 状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<double> get speedStream => _player.speedStream;

  // 当前状态
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  double get volume => _player.volume;
  double get speed => _player.speed;

  // 队列相关
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;
  PlayMode get playMode => _playMode;

  // 播放状态变化回调
  final ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);
  final ValueNotifier<List<Song>> queueNotifier = ValueNotifier([]);
  final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(PlayMode.sequence);

  AudioEngine._internal() {
    _player = AudioPlayer();
    _initAudioSession();
    _setupPlayerListeners();
  }

  /// 初始化音频会话
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// 设置播放器监听器
  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongComplete();
      }
    });
  }

  /// 歌曲播放完成
  void _onSongComplete() {
    switch (_playMode) {
      case PlayMode.single:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case PlayMode.shuffle:
        playRandomNext();
        break;
      default:
        playNext();
    }
  }

  /// 播放单首歌曲
  Future<void> play(Song song) async {
    // 检查是否已在队列中
    final existingIndex = _queue.indexWhere((s) => s.id == song.id);
    if (existingIndex != -1) {
      await playAt(existingIndex);
      return;
    }

    // 添加到队列并播放
    _queue.add(song);
    queueNotifier.value = List.from(_queue);
    await playAt(_queue.length - 1);
  }

  /// 播放队列中指定位置的歌曲
  /// [skipOnFail] 如果为 true，播放失败时自动跳到下一首
  Future<void> playAt(int index, {bool skipOnFail = true}) async {
    if (index < 0 || index >= _queue.length) return;

    _currentIndex = index;
    final song = _queue[index];
    currentSongNotifier.value = song;

    try {
      // 获取歌曲 URL（会尝试多种音质级别）
      debugPrint('正在获取歌曲 URL: ${song.name} (ID: ${song.id})');
      final url = await _musicService.getSongUrl(song.id);
      
      if (url == null || url.isEmpty) {
        debugPrint('⚠️ 无法获取歌曲 URL: ${song.name} - 可能是VIP歌曲或版权限制');
        _onPlayFailed(song, '该歌曲暂时无法播放（版权限制）');
        if (skipOnFail && _queue.length > 1) {
          // 延迟 500ms 后播放下一首，避免太快跳过
          await Future.delayed(const Duration(milliseconds: 500));
          await _playNextAvailable();
        }
        return;
      }

      debugPrint('✅ 获取到 URL，开始播放: ${song.name}');
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      debugPrint('❌ 播放失败: ${song.name} - $e');
      _onPlayFailed(song, '播放出错：$e');
      if (skipOnFail && _queue.length > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _playNextAvailable();
      }
    }
  }

  /// 播放失败回调
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);
  
  void _onPlayFailed(Song song, String message) {
    errorMessageNotifier.value = '${song.name}: $message';
    // 3秒后清除错误消息
    Future.delayed(const Duration(seconds: 3), () {
      if (errorMessageNotifier.value?.contains(song.name) == true) {
        errorMessageNotifier.value = null;
      }
    });
  }

  /// 尝试播放下一首可用的歌曲
  Future<void> _playNextAvailable() async {
    if (_queue.isEmpty) return;
    
    // 记录起始位置，避免无限循环
    final startIndex = _currentIndex;
    int attempts = 0;
    final maxAttempts = _queue.length;
    
    while (attempts < maxAttempts) {
      int nextIndex = (_currentIndex + 1) % _queue.length;
      if (nextIndex == startIndex && attempts > 0) {
        // 已经循环一圈，所有歌曲都无法播放
        debugPrint('所有歌曲都无法播放');
        errorMessageNotifier.value = '播放列表中的歌曲暂时都无法播放';
        return;
      }
      
      _currentIndex = nextIndex;
      attempts++;
      
      final song = _queue[nextIndex];
      currentSongNotifier.value = song;
      
      try {
        final url = await _musicService.getSongUrl(song.id);
        if (url != null && url.isNotEmpty) {
          await _player.setUrl(url);
          await _player.play();
          return; // 成功播放，退出
        }
      } catch (e) {
        debugPrint('尝试播放 ${song.name} 失败: $e');
      }
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    await _player.play();
  }

  /// 切换播放/暂停
  Future<void> togglePlay() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// 播放下一首
  Future<void> playNext() async {
    if (_queue.isEmpty) return;

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      if (_playMode == PlayMode.loop) {
        nextIndex = 0;
      } else {
        return; // 顺序播放到最后一首停止
      }
    }

    await playAt(nextIndex);
  }

  /// 播放上一首
  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;

    // 如果当前播放超过 3 秒，则重新播放当前歌曲
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (_playMode == PlayMode.loop) {
        prevIndex = _queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    await playAt(prevIndex);
  }

  /// 随机播放下一首
  Future<void> playRandomNext() async {
    if (_queue.length <= 1) return;

    int randomIndex;
    do {
      randomIndex = DateTime.now().millisecondsSinceEpoch % _queue.length;
    } while (randomIndex == _currentIndex);

    await playAt(randomIndex);
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    playModeNotifier.value = mode;
  }

  /// 循环切换播放模式
  void togglePlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(_playMode);
    setPlayMode(modes[(currentIndex + 1) % modes.length]);
  }

  /// 设置播放队列
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue.clear();
    _queue.addAll(songs);
    queueNotifier.value = List.from(_queue);

    if (songs.isNotEmpty) {
      await playAt(startIndex.clamp(0, songs.length - 1));
    }
  }

  /// 添加到播放队列
  void addToQueue(Song song) {
    _queue.add(song);
    queueNotifier.value = List.from(_queue);
  }

  /// 添加到下一首播放
  void playNext_add(Song song) {
    final insertIndex = _currentIndex + 1;
    if (insertIndex >= _queue.length) {
      _queue.add(song);
    } else {
      _queue.insert(insertIndex, song);
    }
    queueNotifier.value = List.from(_queue);
  }

  /// 从队列移除
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);
    queueNotifier.value = List.from(_queue);

    // 调整当前索引
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      // 如果移除的是当前播放的歌曲
      if (_queue.isEmpty) {
        _currentIndex = -1;
        currentSongNotifier.value = null;
        _player.stop();
      } else {
        // 播放下一首（索引不变，但歌曲变了）
        playAt(_currentIndex.clamp(0, _queue.length - 1));
      }
    }
  }

  /// 清空队列
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    queueNotifier.value = [];
    currentSongNotifier.value = null;
    _player.stop();
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
    currentSongNotifier.dispose();
    queueNotifier.dispose();
    playModeNotifier.dispose();
  }
}
