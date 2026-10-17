import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';

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
    this.audioDuration,
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

  /// Durasi asli audio (bisa beda beberapa detik dari durasi video YouTube).
  final Duration? audioDuration;
  final bool shuffle;
  final RepeatSetting repeat;

  bool get isPlaying => status == PlaybackStatus.playing;
  Duration get duration => audioDuration ?? current?.duration ?? Duration.zero;
  double get progress =>
      duration.inMilliseconds == 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);

  PlayerState copyWith({
    Track? current,
    List<Track>? upNext,
    List<Track>? played,
    String? source,
    PlaybackStatus? status,
    Duration? position,
    Duration? audioDuration,
    bool clearAudioDuration = false,
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
        audioDuration: clearAudioDuration ? null : (audioDuration ?? this.audioDuration),
        shuffle: shuffle ?? this.shuffle,
        repeat: repeat ?? this.repeat,
      );
}

final playerProvider = NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// Pemutar musik: antrean dikelola di sini, audio diputar `just_audio`
/// (dengan kontrol di notifikasi & lock screen lewat `just_audio_background`).
class PlayerController extends Notifier<PlayerState> {
  final _player = ja.AudioPlayer();
  final _subs = <StreamSubscription<Object?>>[];
  var _loadId = 0;
  var _autoRetried = false;

  @override
  PlayerState build() {
    _subs
      ..add(_player.positionStream.listen((p) {
        if (state.current != null) state = state.copyWith(position: p);
      }))
      ..add(_player.durationStream.listen((d) {
        if (d != null) state = state.copyWith(audioDuration: d);
      }))
      ..add(_player.playerStateStream.listen(_onPlayerState, onError: _onPlaybackError));
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player.dispose();
    });
    return const PlayerState();
  }

  void _onPlayerState(ja.PlayerState s) {
    if (state.current == null || state.status == PlaybackStatus.error) return;
    switch (s.processingState) {
      case ja.ProcessingState.loading || ja.ProcessingState.buffering:
        state = state.copyWith(status: PlaybackStatus.buffering);
      case ja.ProcessingState.ready:
        _autoRetried = false;
        state = state.copyWith(status: s.playing ? PlaybackStatus.playing : PlaybackStatus.paused);
      case ja.ProcessingState.completed:
        if (state.repeat == RepeatSetting.one) {
          _player.seek(Duration.zero);
        } else {
          next();
        }
      case ja.ProcessingState.idle:
        break;
    }
  }

  void _onPlaybackError(Object error, StackTrace _) {
    debugPrint('Playback error: $error');
    // URL stream YouTube kedaluwarsa setelah beberapa jam: ambil ulang sekali secara otomatis.
    if (!_autoRetried && state.current != null) {
      _autoRetried = true;
      retry();
      return;
    }
    state = state.copyWith(status: PlaybackStatus.error);
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

  /// Putar satu lagu (mis. dari hasil pencarian); antrean diisi lagu serupa bila autoplay aktif.
  void playSingle(Track track, {required String source}) {
    state = state.copyWith(played: const [], upNext: const [], source: source);
    _load(track);
    if (ref.read(settingsProvider).autoplay) unawaited(_fillQueueWithRelated(track));
  }

  Future<void> _fillQueueWithRelated(Track seed) async {
    try {
      final related = await ref.read(musicRepositoryProvider).related(seed);
      // Abaikan bila user sudah pindah lagu atau mengisi antrean sendiri.
      if (state.current != seed || state.upNext.isNotEmpty) return;
      state = state.copyWith(upNext: related);
    } catch (e) {
      debugPrint('Gagal mengisi antrean: $e');
    }
  }

  void togglePlay() {
    switch (state.status) {
      case PlaybackStatus.playing:
        _player.pause();
      case PlaybackStatus.paused:
        _player.play();
      case PlaybackStatus.error:
        retry();
      case PlaybackStatus.idle || PlaybackStatus.buffering:
        break;
    }
  }

  /// Muat ulang lagu saat ini (URL baru) dan lanjutkan dari posisi terakhir.
  void retry() {
    final t = state.current;
    if (t != null) _load(t, startAt: state.position, recordHistory: false);
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
        _player.pause();
        _player.seek(Duration.zero);
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

  void seek(Duration position) {
    state = state.copyWith(position: position);
    _player.seek(position);
  }

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

  /// Hentikan pemutaran & kosongkan antrean (dipakai saat logout).
  Future<void> stop() async {
    _loadId++;
    await _player.stop();
    state = const PlayerState();
  }

  Future<void> _autoplayFrom(Track seed) async {
    try {
      final related = await ref.read(musicRepositoryProvider).related(seed);
      final fresh = related.where((t) => t != seed && !state.played.contains(t)).toList();
      if (fresh.isEmpty) return;
      state = state.copyWith(played: [...state.played, seed], upNext: fresh.sublist(1), source: 'Autoplay');
      _load(fresh.first);
    } catch (e) {
      debugPrint('Autoplay gagal: $e');
    }
  }

  Future<void> _load(Track track, {Duration startAt = Duration.zero, bool recordHistory = true}) async {
    final id = ++_loadId;
    state = state.copyWith(
      current: track,
      status: PlaybackStatus.buffering,
      position: startAt,
      clearAudioDuration: startAt == Duration.zero,
    );
    try {
      final quality = ref.read(settingsProvider).quality;
      final url = await ref.read(musicRepositoryProvider).streamUrl(track.videoId, quality: quality);
      if (id != _loadId) return;
      await _player.setAudioSource(
        ja.AudioSource.uri(
          url,
          tag: MediaItem(
            id: track.videoId,
            title: track.title,
            artist: track.artist,
            duration: track.duration,
            artUri: track.thumbnail == null ? null : Uri.parse(track.thumbnail!),
          ),
        ),
        initialPosition: startAt,
      );
      if (id != _loadId) return;
      unawaited(_player.play());
      if (recordHistory) {
        // → POST /history (backend). Gagal pun tidak mengganggu pemutaran.
        unawaited(ref
            .read(libraryRepositoryProvider)
            .addHistory(track)
            .then((_) => ref.invalidate(historyProvider))
            .catchError((Object e) => debugPrint('Gagal mencatat riwayat: $e')));
      }
    } catch (e) {
      debugPrint('Gagal memuat ${track.videoId}: $e');
      if (id == _loadId) state = state.copyWith(status: PlaybackStatus.error);
    }
  }
}
