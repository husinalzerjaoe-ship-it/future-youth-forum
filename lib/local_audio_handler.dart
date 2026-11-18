import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class LocalAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  LocalAudioHandler() {
    _player.playbackEventStream.listen((_) {
      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _processingState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ));
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  AudioProcessingState _processingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  Future<void> loadLocalQueue(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) {
      await stop();
      return;
    }
    if (initialIndex < 0 || initialIndex >= items.length) {
      throw RangeError.index(initialIndex, items);
    }
    final sources = items.map((item) {
      final uri = Uri.file(item.id);
      return AudioSource.uri(uri, tag: item);
    }).toList(growable: false);
    await _setQueue(items, sources, initialIndex);
  }

  /// Loads a complete queue of public shared audio URLs. Keeping the queue in
  /// AudioService makes next/previous controls work from the lock screen too.
  Future<void> loadRemoteQueue(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) {
      await stop();
      return;
    }
    if (initialIndex < 0 || initialIndex >= items.length) {
      throw RangeError.index(initialIndex, items);
    }
    final sources = items.map((item) {
      final uri = Uri.tryParse(item.id);
      if (uri == null || !const ['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
        throw ArgumentError('رابط إحدى الأغاني غير صالح: ${item.title}');
      }
      return AudioSource.uri(uri, tag: item);
    }).toList(growable: false);
    await _setQueue(items, sources, initialIndex);
  }

  Future<void> _setQueue(
    List<MediaItem> items,
    List<AudioSource> sources,
    int initialIndex,
  ) async {
    queue.add(List<MediaItem>.unmodifiable(items));
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );
    mediaItem.add(items[initialIndex]);
  }

  Future<void> loadRemoteTrack(String url, String title) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !const ['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
      throw ArgumentError('رابط الأغنية غير صالح أو ليس رابط ملف صوتي مباشر.');
    }
    await loadRemoteQueue([
      MediaItem(id: url, title: title, album: 'مكتبة المجتمع'),
    ]);
    await play();
  }

  @override Future<void> play() => _player.play();
  @override Future<void> pause() => _player.pause();
  @override Future<void> stop() async {
    await _player.stop();
    queue.add([]);
    mediaItem.add(null);
    await super.stop();
  }
  @override Future<void> seek(Duration position) => _player.seek(position);
  @override Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);
  @override Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }
  @override Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    }
  }
}

late LocalAudioHandler appAudioHandler;
bool isAudioServiceInitialized = false;
Future<LocalAudioHandler>? _audioInitialization;

Future<void> initializeLocalAudioService() async {
  if (isAudioServiceInitialized) return;
  _audioInitialization ??= AudioService.init<LocalAudioHandler>(
    builder: LocalAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.futureyouth.forum.local_audio',
      androidNotificationChannelName: 'موسيقى ملتقى شباب المستقبل',
      androidNotificationOngoing: true,
    ),
  );
  try {
    appAudioHandler = await _audioInitialization!;
    isAudioServiceInitialized = true;
  } catch (_) {
    _audioInitialization = null;
    rethrow;
  }
}
