import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class FileUploadService {
  Future<List<String>?> pickAndUploadAudio({
    required String backendHost,
    required String selectedLanguage,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'webm', 'm4a', 'aac', 'ogg', 'flac', 'mp4'],
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final fileName = file.name;
    String? filePath;

    if (!kIsWeb) {
      try {
        filePath = file.path;
      } catch (_) {}
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://$backendHost/transcribe'),
    );
    request.fields['language_mode'] = selectedLanguage;

    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('audio_file', filePath));
    } else if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'audio_file',
        file.bytes!,
        filename: fileName,
      ));
    } else {
      throw Exception('Cannot read file data. Please select a valid audio file.');
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      final List<String> extractedTranscripts = [];

      if (data['title'] != null) {
        extractedTranscripts.add('Meeting: ${data['title']}');
      }
      if (data['segments'] != null) {
        for (var segment in data['segments']) {
          extractedTranscripts.add(
            '[${segment['speaker']}] (${segment['language']}): ${segment['text']}',
          );
        }
      }
      return extractedTranscripts;
    } else {
      throw Exception('Error uploading file (${response.statusCode}): $responseData');
    }
  }
}