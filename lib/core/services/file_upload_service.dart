import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms/core/constants/app_config.dart';
import 'package:path/path.dart' as p;

class FileUploadService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the device gallery and returns the picked file, or `null`.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Compresses [file] if it's an image (jpg/png) and uploads to VPS API.
  Future<String?> uploadFile(
    File file, {
    String folderType = 'profiles',
  }) async {
    File fileToUpload = file;
    File? tempCompressedFile;

    // Check file extension to determine if compression is needed
    final ext = p.extension(file.path).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
      tempCompressedFile = await _compressImage(file);
      if (tempCompressedFile != null) {
        fileToUpload = tempCompressedFile;
      }
    }

    try {
      final uri = Uri.parse(AppConfig.uploadFileUrl);
      final request = http.MultipartRequest('POST', uri);

      // Add file field named 'file'
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          fileToUpload.path,
          filename: p.basename(fileToUpload.path),
        ),
      );

      // Add folder_type field
      request.fields['folder_type'] = folderType;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['public_url'] != null) {
          return body['public_url'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('FileUploadService Error: $e');
      return null;
    } finally {
      // Clean up temporary compressed file
      if (tempCompressedFile != null) {
        try {
          if (await tempCompressedFile.exists()) {
            await tempCompressedFile.delete();
          }
        } catch (_) {}
      }
    }
  }

  /// Helper to compress image file.
  Future<File?> _compressImage(File file) async {
    try {
      final targetPath =
          '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 512,
        minHeight: 512,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a file from the VPS API.
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(AppConfig.deleteFileUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_url': fileUrl}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
