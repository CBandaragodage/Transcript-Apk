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
  String selectedLanguage = 'English';
  List<String> transcripts = [];

  final AudioTranscriptionService _audioService = AudioTranscriptionService();
  final FileUploadService _uploadService = FileUploadService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      setState(() => isRecording = false);
      await _audioService.stopLiveStream();
    } else {
      if (await _audioService.hasPermission()) {
        setState(() {
          isRecording = true;
          transcripts.add('Connecting to live stream...');
        });

        await _audioService.startLiveStream(
          selectedLanguage: selectedLanguage,
          onMessage: (msg) => setState(() => transcripts.add(msg)),
          onError: (err) => setState(() => transcripts.add(err)),
          onDone: () => setState(() => transcripts.add('WebSocket Closed by server')),
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

      if (results != null) {
        setState(() {
          transcripts.addAll(results);
        });
      }
    } catch (e) {
      setState(() {
        transcripts.add('Exception uploading file: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color(0xFF4C6A9C);
    const Color pageBackground = Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('SLT 1.0 Live Transcriber'),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Language Selector Dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLanguage,
                        isExpanded: true,
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
                ],
              ),
            ),
            // Transcripts Display Box
            Expanded(
              child: transcripts.isEmpty
                  ? Center(
                      child: Text(
                        'Transcript will appear here.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: transcripts.length,
                      itemBuilder: (context, index) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              transcripts[index],
                              style: const TextStyle(fontSize: 15),
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
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? Colors.redAccent : Colors.blueAccent,
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? Colors.redAccent : Colors.blueAccent)
                                  .withValues(alpha: 0.28),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording ? Icons.stop_rounded : Icons.mic,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: FloatingActionButton.small(
                      onPressed: uploadFile,
                      backgroundColor: Colors.white,
                      foregroundColor: appBarColor,
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