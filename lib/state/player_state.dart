import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/core/audio_engine.dart';

/// 音频引擎 Provider
final audioEngineProvider = Provider<AudioEngine>((ref) {
  return AudioEngine();
});

/// 当前播放歌曲 Provider
final currentSongProvider = StreamProvider<Song?>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.currentSongNotifier.toStream();
});

/// 播放队列 Provider
final playQueueProvider = StreamProvider<List<Song>>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.queueNotifier.toStream();
});

/// 播放模式 Provider
final playModeProvider = StreamProvider<PlayMode>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.playModeNotifier.toStream();
});

/// 播放状态 Provider
final playerStateProvider = StreamProvider((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.playerStateStream;
});

/// 播放进度 Provider
final positionProvider = StreamProvider<Duration>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.positionStream;
});

/// 歌曲时长 Provider
final durationProvider = StreamProvider<Duration?>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.durationStream;
});

/// ValueNotifier 扩展：转换为 Stream
extension ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() async* {
    yield value;
    await for (final _ in _notifierStream(this)) {
      yield value;
    }
  }
}

Stream<void> _notifierStream(Listenable listenable) {
  late final void Function() listener;
  return Stream<void>.multi((controller) {
    listener = () => controller.add(null);
    listenable.addListener(listener);
  }).asBroadcastStream(
    onCancel: (sub) => listenable.removeListener(listener),
  );
}
