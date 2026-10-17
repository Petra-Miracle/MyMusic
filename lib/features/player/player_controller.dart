import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

enum PlaybackStatus { idle, buffering, playing, paused, error }

enum RepeatSetting { off, all, one }

class PlayerState {
  const PlayerState({
    this.current,
    this.upNext = const [],
    this.played = const [],
    this.source = '',
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.shuffle = false,
    this.repeat = RepeatSetting.off,
  });

  final Track? current;

  /// Antrean "Berikutnya".
  final List<Track> upNext;

  /// Lagu yang sudah lewat (untuk tombol previous).
  final List<Track> played;

  /// Ditampilkan di Now Playing: "Diputar dari: …".
  final String source;
  final PlaybackStatus status;
  final Duration position;
  final bool shuffle;
  final RepeatSetting repeat;

  bool get isPlaying => status == PlaybackStatus.playing;
  Duration get duration => current?.duration ?? Duration.zero;
  double get progress =>
      duration.inMilliseconds == 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);

  PlayerState copyWith({
    Track? current,
    List<Track>? upNext,
    List<Track>? played,
    String? source,
    PlaybackStatus? status,
    Duration? position,
    bool? shuffle,
    RepeatSetting? repeat,
  }) =>
      PlayerState(
        current: current ?? this.current,
        upNext: upNext ?? this.upNext,
        played: played ?? this.played,
        source: source ?? this.source,
        status: status ?? this.status,
        position: position ?? this.position,
        shuffle: shuffle ?? this.shuffle,
        repeat: repeat ?? this.repeat,
      );
}

final playerProvider = NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// Pemutar musik.
///
/// TAHAP UI: playback disimulasikan dengan timer. Nanti `_load` diganti
/// `MusicRepository.streamUrl` + `just_audio`, dan `_tick` diganti stream
/// posisi dari `AudioPlayer`. API publik controller ini tidak berubah.
class PlayerController extends Notifier<PlayerState> {
  Timer? _ticker;
  var _loadId = 0;

  @override
  PlayerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const PlayerState();
  }

  /// Putar [tracks] mulai dari [index]. Sisa daftar masuk antrean.
  void playTracks(List<Track> tracks, int index, {required String source}) {
    final rest = tracks.sublist(index + 1);
    state = state.copyWith(
      played: tracks.sublist(0, index),
      upNext: state.shuffle ? (rest..shuffle()) : rest,
      source: source,
    );
    _load(tracks[index]);
  }

  void togglePlay() {
    switch (state.status) {
      case PlaybackStatus.playing:
        state = state.copyWith(status: PlaybackStatus.paused);
      case PlaybackStatus.paused:
        state = state.copyWith(status: PlaybackStatus.playing);
      case PlaybackStatus.error:
        retry();
      case PlaybackStatus.idle || PlaybackStatus.buffering:
        break;
    }
  }

  void retry() {
    final t = state.current;
    if (t != null) _load(t);
  }

  void next() {
    final current = state.current;
    if (current == null) return;
    if (state.upNext.isEmpty) {
      if (state.repeat == RepeatSetting.all && state.played.isNotEmpty) {
        final all = [...state.played, current];
        state = state.copyWith(played: const [], upNext: all.sublist(1));
        _load(all.first);
      } else if (ref.read(settingsProvider).autoplay) {
        _autoplayFrom(current);
      } else {
        state = state.copyWith(status: PlaybackStatus.paused, position: Duration.zero);
      }
      return;
    }
    final upcoming = state.upNext.first;
    state = state.copyWith(played: [...state.played, current], upNext: state.upNext.sublist(1));
    _load(upcoming);
  }

  void previous() {
    if (state.position > const Duration(seconds: 3) || state.played.isEmpty) {
      seek(Duration.zero);
      return;
    }
    final prev = state.played.last;
    state = state.copyWith(
      played: state.played.sublist(0, state.played.length - 1),
      upNext: [state.current!, ...state.upNext],
    );
    _load(prev);
  }

  void seek(Duration position) => state = state.copyWith(position: position);

  void toggleShuffle() {
    final on = !state.shuffle;
    state = state.copyWith(shuffle: on, upNext: on ? ([...state.upNext]..shuffle(Random())) : null);
  }

  void cycleRepeat() =>
      state = state.copyWith(repeat: RepeatSetting.values[(state.repeat.index + 1) % RepeatSetting.values.length]);

  void playNext(Track t) => state = state.copyWith(upNext: [t, ...state.upNext.where((x) => x != t)]);

  void addToQueue(Track t) => state = state.copyWith(upNext: [...state.upNext.where((x) => x != t), t]);

  /// Lompat ke lagu ke-[index] di antrean; lagu yang dilewati masuk ke "sudah diputar".
  void skipTo(int index) {
    final current = state.current;
    if (current == null || index >= state.upNext.length) return;
    final target = state.upNext[index];
    state = state.copyWith(
      played: [...state.played, current, ...state.upNext.take(index)],
      upNext: state.upNext.sublist(index + 1),
    );
    _load(target);
  }

  void removeFromQueue(int index) => state = state.copyWith(upNext: [...state.upNext]..removeAt(index));

  /// [newIndex] sudah disesuaikan (posisi setelah item lama dihapus).
  void reorderQueue(int oldIndex, int newIndex) {
    final list = [...state.upNext];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(upNext: list);
  }

  Future<void> _autoplayFrom(Track seed) async {
    final related = await ref.read(musicRepositoryProvider).related(seed);
    final fresh = related.where((t) => t != seed && !state.played.contains(t)).toList();
    if (fresh.isEmpty) return;
    state = state.copyWith(played: [...state.played, seed], upNext: fresh.sublist(1), source: 'Autoplay');
    _load(fresh.first);
  }

  Future<void> _load(Track track) async {
    final id = ++_loadId;
    _ticker?.cancel();
    state = state.copyWith(current: track, status: PlaybackStatus.buffering, position: Duration.zero);
    try {
      await ref.read(musicRepositoryProvider).streamUrl(track.videoId);
      await Future.delayed(const Duration(milliseconds: 700));
      if (id != _loadId) return;
      state = state.copyWith(status: PlaybackStatus.playing);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      // → POST /history (backend). Fire-and-forget, tidak mengganggu pemutaran.
      unawaited(ref.read(libraryRepositoryProvider).addHistory(track).then((_) => ref.invalidate(historyProvider)));
    } catch (_) {
      if (id == _loadId) state = state.copyWith(status: PlaybackStatus.error);
    }
  }

  void _tick() {
    if (state.status != PlaybackStatus.playing) return;
    final pos = state.position + const Duration(seconds: 1);
    if (pos < state.duration) {
      state = state.copyWith(position: pos);
    } else if (state.repeat == RepeatSetting.one) {
      state = state.copyWith(position: Duration.zero);
    } else {
      next();
    }
  }
}
