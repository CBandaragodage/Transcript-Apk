import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AudioTranscriptionService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription? _audioStreamSubscription;
  Timer? _chunkTimer;
  final List<int> _audioBuffer = [];

  // Localhost routing based on environment
  String get backendHost {
    if (kIsWeb) return '127.0.0.1:8000';
    try {
      // 10.0.2.2 is the host loopback IP for Android Emulators
      if (Platform.isAndroid) return '10.0.2.2:8000';
    } catch (_) {}
    return '127.0.0.1:8000';
  }

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startLiveStream({
    required String selectedLanguage,
    required Function(String) onMessage,
    required Function(String) onError,
    required Function() onDone,
  }) async {
    // Stop any existing stream before starting a new one
    await stopLiveStream();

    _audioBuffer.clear();
    final encodedLang = Uri.encodeComponent(selectedLanguage);

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$backendHost/stream?language_mode=$encodedLang'),
      );

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['status'] == 'success' || data['status'] == 'error') {
              onMessage('${data['language']}: ${data['text']}');
            }
          } catch (e) {
            onError('Error decoding WebSocket: $e');
          }
        },
        onError: (error) => onError('WebSocket Error: $error'),
        onDone: () => onDone(),
      );

      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioStreamSubscription = stream.listen((data) {
        _audioBuffer.addAll(data);
      });

      // Send buffered audio PCM chunks every 2 seconds
      _chunkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_channel != null && _audioBuffer.isNotEmpty) {
          _channel!.sink.add(Uint8List.fromList(_audioBuffer));
          _audioBuffer.clear();
        }
      });
    } catch (e) {
      onError('Failed to start audio stream: $e');
    }
  }

  Future<void> stopLiveStream() async {
    _chunkTimer?.cancel();
    _chunkTimer = null;

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    await _channel?.sink.close();
    _channel = null;
    _audioBuffer.clear();
  }

  void dispose() {
    stopLiveStream();
    _audioRecorder.dispose();
  }
}