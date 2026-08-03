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

  String get backendHost {
    if (kIsWeb) return '127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return '127.0.0.1:8000';
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
    _audioBuffer.clear();
    final encodedLang = Uri.encodeComponent(selectedLanguage);

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

    _chunkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_channel != null && _audioBuffer.isNotEmpty) {
        _channel!.sink.add(Uint8List.fromList(_audioBuffer));
        _audioBuffer.clear();
      }
    });
  }

  Future<void> stopLiveStream() async {
    _chunkTimer?.cancel();
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    await _channel?.sink.close();
    _channel = null;
    _audioBuffer.clear();
  }

  void dispose() {
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _channel?.sink.close();
  }
}