import 'package:flutter/material.dart';
import '../services/audio_transcription_service.dart';
import '../services/file_upload_service.dart';

class LiveTranscriptionPage extends StatefulWidget {
  const LiveTranscriptionPage({super.key});

  @override
  State<LiveTranscriptionPage> createState() => _LiveTranscriptionPageState();
}

class _LiveTranscriptionPageState extends State<LiveTranscriptionPage> {
  bool isRecording = false;
  String selectedLanguage = 'Singlish (kohomada)';
  List<String> transcripts = [];

  final AudioTranscriptionService _audioService = AudioTranscriptionService();
  final FileUploadService _uploadService = FileUploadService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-start recording when screen opens from dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toggleRecording();
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      if (mounted) setState(() => isRecording = false);
      await _audioService.stopLiveStream();
    } else {
      bool hasPermission = await _audioService.hasPermission();
      if (!mounted) return;

      if (hasPermission) {
        setState(() {
          isRecording = true;
          transcripts.add('Connecting to live stream...');
        });
        _scrollToBottom();

        await _audioService.startLiveStream(
          selectedLanguage: selectedLanguage,
          onMessage: (msg) {
            if (mounted) {
              setState(() => transcripts.add(msg));
              _scrollToBottom();
            }
          },
          onError: (err) {
            if (mounted) {
              setState(() => transcripts.add(err));
              _scrollToBottom();
            }
          },
          onDone: () {
            if (mounted) {
              setState(() => transcripts.add('WebSocket closed by server'));
              _scrollToBottom();
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
    }
  }

  Future<void> uploadFile() async {
    try {
      final results = await _uploadService.pickAndUploadAudio(
        backendHost: _audioService.backendHost,
        selectedLanguage: selectedLanguage,
      );

      if (!mounted) return;

      if (results != null) {
        setState(() {
          transcripts.addAll(results);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        transcripts.add('Exception uploading file: $e');
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          'Live Transcriber',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Language Selector Dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF161B22),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(
                          value: 'Sinhala Script (කොහොමද)',
                          child: Text('Sinhala Script (කොහොමද)'),
                        ),
                        DropdownMenuItem(
                          value: 'Singlish (kohomada)',
                          child: Text('Singlish (kohomada)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedLanguage = value);
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Transcripts Display Box
            Expanded(
              child: transcripts.isEmpty
                  ? Center(
                      child: Text(
                        'Tap the mic to start live transcription...',
                        style: TextStyle(color: const Color(0xFF8B949E), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: transcripts.length,
                      itemBuilder: (context, index) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF30363D)),
                            ),
                            child: Text(
                              transcripts[index],
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Action Controls (Mic & Upload)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: toggleRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? Colors.redAccent : const Color(0xFF0072CE),
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? Colors.redAccent : const Color(0xFF0072CE))
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording ? Icons.stop_rounded : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: FloatingActionButton.small(
                      onPressed: uploadFile,
                      backgroundColor: const Color(0xFF161B22),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.upload_file),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}