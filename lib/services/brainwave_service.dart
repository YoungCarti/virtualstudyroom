
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';

enum BrainwaveMode {
  deepFocus,
  creative,
  cram,
}

class BrainwaveState {
  final bool isPlaying;
  final BrainwaveMode mode;
  final Duration position;
  final Duration? duration;
  final double volume;
  final String currentTitle;
  final String currentArtist;

  BrainwaveState({
    this.isPlaying = false,
    this.mode = BrainwaveMode.deepFocus,
    this.position = Duration.zero,
    this.duration,
    this.volume = 1.0,
    this.currentTitle = 'Deep Focus',
    this.currentArtist = 'Brainwave Station',
  });

  BrainwaveState copyWith({
    bool? isPlaying,
    BrainwaveMode? mode,
    Duration? position,
    Duration? duration,
    double? volume,
    String? currentTitle,
    String? currentArtist,
  }) {
    return BrainwaveState(
      isPlaying: isPlaying ?? this.isPlaying,
      mode: mode ?? this.mode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
    );
  }
}

class BrainwaveService extends ChangeNotifier {
  static final BrainwaveService _instance = BrainwaveService._internal();
  factory BrainwaveService() => _instance;

  BrainwaveService._internal() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  BrainwaveState _state = BrainwaveState();
  final Completer<void> _assetsLoaded = Completer<void>();

  BrainwaveState get state => _state;

  // Asset Paths (Loaded dynamically)
  Map<BrainwaveMode, List<String>> _audioAssets = {
    BrainwaveMode.deepFocus: [],
    BrainwaveMode.creative: [],
    BrainwaveMode.cram: [],
  };

  // Base Metadata
  final Map<BrainwaveMode, Map<String, String>> _modeMetadata = {
    BrainwaveMode.deepFocus: {
      'title': 'Deep Focus',
      'artist': 'Binaural Beats'
    },
    BrainwaveMode.creative: {
      'title': 'Lofi Chill',
      'artist': 'Relaxing Vibes'
    },
    BrainwaveMode.cram: {
      'title': 'High Energy',
      'artist': 'Study Power'
    },
  };

  void _initPlayer() {
    _loadAssets(); // Start loading assets

    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      if (_state.isPlaying != isPlaying) {
        _state = _state.copyWith(isPlaying: isPlaying);
        notifyListeners();
      }
    });

    _player.positionStream.listen((position) {
      _state = _state.copyWith(position: position);
      notifyListeners(); 
    });
    
    _player.durationStream.listen((duration) {
       _state = _state.copyWith(duration: duration);
       notifyListeners();
    });

    // Listen for track changes to update title with Track Number
    _player.currentIndexStream.listen((index) {
       if (index != null) {
         final modeMeta = _modeMetadata[_state.mode];
         if (modeMeta != null) {
            _state = _state.copyWith(
              currentTitle: "${modeMeta['title']} ${index + 1}",
              currentArtist: modeMeta['artist'],
            );
            notifyListeners();
         }
       }
    });
  }

  Future<void> _loadAssets() async {
    try {
      debugPrint("BrainwaveService: Loading assets...");
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      debugPrint("BrainwaveService: Manifest Keys Found: ${manifestMap.keys.length}"); 
      
      final deepFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/audio/deep/') && 
                          (key.endsWith('.mp3') || key.endsWith('.wav') || key.endsWith('.ogg')))
          .toList();
          
      final creativeFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/audio/creative/') && 
                          (key.endsWith('.mp3') || key.endsWith('.wav') || key.endsWith('.ogg')))
          .toList();

      final cramFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/audio/cram/') && 
                          (key.endsWith('.mp3') || key.endsWith('.wav') || key.endsWith('.ogg')))
          .toList();

      // FALLBACK: If manifest filtering failed (zero files) but we know they exist
      if (deepFiles.isEmpty) {
         debugPrint("BrainwaveService: No deep files found in manifest. Attempting fallback.");
         deepFiles.addAll([
           'assets/audio/deep/Deep1.mp3',
           'assets/audio/deep/Deep2.mp3',
           'assets/audio/deep/Deep3.mp3',
         ]);
      }

      if (creativeFiles.isEmpty) {
         debugPrint("BrainwaveService: No creative files found in manifest. Attempting fallback.");
         creativeFiles.addAll([
           'assets/audio/creative/Lofi1.mp3',
           'assets/audio/creative/Lofi2.mp3',
           'assets/audio/creative/Lofi3.mp3',
         ]);
      }

      if (cramFiles.isEmpty) {
         debugPrint("BrainwaveService: No cram files found in manifest. Attempting fallback.");
         cramFiles.addAll([
           'assets/audio/cram/Cram1.mp3',
           'assets/audio/cram/Cram2.mp3',
           'assets/audio/cram/Cram3.mp3',
         ]);
      }

      _audioAssets[BrainwaveMode.deepFocus] = deepFiles;
      _audioAssets[BrainwaveMode.creative] = creativeFiles;
      _audioAssets[BrainwaveMode.cram] = cramFiles;
      
      notifyListeners();
      debugPrint("BrainwaveService: Assets set. Deep=${deepFiles.length}, Creative=${creativeFiles.length}, Cram=${cramFiles.length}");
      if (!_assetsLoaded.isCompleted) _assetsLoaded.complete();
    } catch (e) {
      debugPrint("BrainwaveService: Error loading assets manifest: $e");
      // Fallback on error too
       _audioAssets[BrainwaveMode.deepFocus] = [
           'assets/audio/deep/Deep1.mp3',
           'assets/audio/deep/Deep2.mp3',
           'assets/audio/deep/Deep3.mp3',
       ];
       _audioAssets[BrainwaveMode.creative] = [
           'assets/audio/creative/Lofi1.mp3',
           'assets/audio/creative/Lofi2.mp3',
           'assets/audio/creative/Lofi3.mp3',
       ];
       _audioAssets[BrainwaveMode.cram] = [
           'assets/audio/cram/Cram1.mp3',
           'assets/audio/cram/Cram2.mp3',
           'assets/audio/cram/Cram3.mp3',
       ];
      if (!_assetsLoaded.isCompleted) _assetsLoaded.complete();
    }
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    _state = _state.copyWith(volume: clampedVolume);
    notifyListeners();
    await _player.setVolume(clampedVolume);
  }

  Future<void> setMode(BrainwaveMode mode) async {
    // Basic metadata update before load
    final meta = _modeMetadata[mode]!;
    _state = _state.copyWith(
      mode: mode,
      currentTitle: "${meta['title']} 1",
      currentArtist: meta['artist'],
    );
    notifyListeners();

    if (_state.mode == mode && _state.isPlaying) return;

    // Ensure assets are loaded for this mode
    await _assetsLoaded.future;
    
    // RETRY LOGIC: If still empty, try loading again (maybe singleton init race)
    if (_audioAssets[mode]?.isEmpty ?? true) {
       debugPrint("BrainwaveService: Assets empty for $mode, retrying load...");
       await _loadAssets();
    }
    
    final assets = _audioAssets[mode];     

    try {
      if (assets != null && assets.isNotEmpty) {
        final playlist = ConcatenatingAudioSource(
          children: assets.map((path) => AudioSource.asset(path)).toList(),
        );

        try {
          await _player.setAudioSource(playlist);
        } catch (e) {
          debugPrint("Error loading playlist for $mode: $e");
        }
        
        if (_state.isPlaying) {
            _player.play();
        }
      } else {
        debugPrint("No assets found for mode: $mode");
        _state = _state.copyWith(isPlaying: false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error setting mode: $e");
      _state = _state.copyWith(isPlaying: false);
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      // If no source is loaded (e.g. first run), load current mode
      if (_player.duration == null) {
         await setMode(_state.mode);
      }
      await _player.play();
    }
  }
  
  Future<void> stop() async {
     await _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

