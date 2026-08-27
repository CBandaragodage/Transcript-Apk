import 'package:flutter/material.dart';
import '../services/audio_transcription_service.dart';
import '../services/file_upload_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final AudioTranscriptionService _transcriptionService = AudioTranscriptionService();
  final FileUploadService _fileUploadService = FileUploadService();

  bool _isUploading = false;
  final String _selectedLanguage = 'Singlish';

  // Handle Live Recording Action
  Future<void> _handleLiveRecord() async {
    // Check Permission & Navigate to Live Transcription Page
    bool hasPermission = await _transcriptionService.hasPermission();
    if (!mounted) return;

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
      return;
    }

    // Open Live Transcription Screen
    Navigator.pushNamed(context, '/transcription');
  }

  // Handle Audio File Upload
  Future<void> _handleUploadAudio() async {
    setState(() => _isUploading = true);
    try {
      final results = await _fileUploadService.pickAndUploadAudio(
        backendHost: _transcriptionService.backendHost,
        selectedLanguage: _selectedLanguage,
      );

      if (!mounted) return;

      if (results != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File processed! Transcribed ${results.length} lines.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _transcriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF161B22),
              child: Icon(Icons.person, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('SLT Stitch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('User Profile Active', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'START NEW SESSION',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),

            // Top Action Cards
            Row(
              children: [
                // Live Record Action Card
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.mic_rounded,
                    label: 'Live Record',
                    color: const Color(0xFF0072CE),
                    onTap: _handleLiveRecord,
                  ),
                ),
                const SizedBox(width: 10),

                // Upload Audio Action Card
                Expanded(
                  child: _buildActionCard(
                    icon: _isUploading ? Icons.hourglass_top_rounded : Icons.note_add_rounded,
                    label: _isUploading ? 'Uploading...' : 'Upload Audio',
                    color: const Color(0xFF00C853),
                    onTap: _isUploading ? () {} : _handleUploadAudio,
                  ),
                ),
                const SizedBox(width: 10),

                // Join Meeting Action Card
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.groups_rounded,
                    label: 'Join Meeting',
                    color: const Color(0xFF30363D),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Join Meeting clicked')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search title, ID, or words...',
                hintStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B949E)),
                suffixIcon: const Icon(Icons.tune, color: Color(0xFF8B949E)),
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Button Widget Builder
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}