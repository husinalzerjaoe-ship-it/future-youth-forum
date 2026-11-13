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

  Future<void> loadLocalQueue(List<MediaItem> items) async {
    queue.add(items);
    if (items.isEmpty) {
      await _player.stop();
      return;
    }
    await _player.setAudioSource(ConcatenatingAudioSource(children: items.map((item) =>
      AudioSource.uri(Uri.file(item.id), tag: item)
    ).toList()));
  }

  @override Future<void> play() => _player.play();
  @override Future<void> pause() => _player.pause();
  @override Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  @override Future<void> seek(Duration position) => _player.seek(position);
  @override Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);
  @override Future<void> skipToNext() => _player.seekToNext();
  @override Future<void> skipToPrevious() => _player.seekToPrevious();
}

late LocalAudioHandler appAudioHandler;

Future<void> initializeLocalAudioService() async {
  appAudioHandler = await AudioService.init(
    builder: LocalAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.futureyouth.forum.local_audio',
      androidNotificationChannelName: 'موسيقى ملتقى الأنمي',
      androidNotificationOngoing: true,
    ),
  );
}
