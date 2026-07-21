import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/upload.dart';

class UploadApi {
  UploadApi(this._client);

  final DioClient _client;

  Future<List<StaffLessonOption>> getLessons(String type) async {
    final response = await _client.dio.get('/homework/lessons', queryParameters: {'type': type});
    return (response.data['data'] as List<dynamic>)
        .map((e) => StaffLessonOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MultipartFile> _filePart({
    required String fieldName,
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    if (bytes != null) {
      return MultipartFile.fromBytes(bytes, filename: fileName);
    }
    if (filePath != null) {
      return MultipartFile.fromFile(filePath, filename: fileName);
    }
    throw ArgumentError('filePath or bytes is required for $fieldName');
  }

  Future<ParseImportResult> parseDocx({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'file': await _filePart(fieldName: 'file', filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/upload/parse-docx', data: form);
    return ParseImportResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ParseImportResult> parseOcr({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'image': await _filePart(fieldName: 'image', filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/upload/parse-ocr', data: form);
    return ParseImportResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BulkImportResult> bulkImportWords({
    required String lessonId,
    required List<ImportPair> pairs,
  }) async {
    final response = await _client.dio.post('/upload/bulk-import/words', data: {
      'lessonId': lessonId,
      'pairs': pairs.map((p) => p.toJson()).toList(),
    });
    return BulkImportResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BulkImportResult> bulkImportSentences({
    required String lessonId,
    required List<ImportPair> pairs,
  }) async {
    final response = await _client.dio.post('/upload/bulk-import/sentences', data: {
      'lessonId': lessonId,
      'pairs': pairs.map((p) => p.toJson()).toList(),
    });
    return BulkImportResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<UploadedFileInfo> uploadImage({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'image': await _filePart(fieldName: 'image', filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/upload/image', data: form);
    return UploadedFileInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<UploadedFileInfo> uploadAudio({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'audio': await _filePart(fieldName: 'audio', filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/upload/audio', data: form);
    return UploadedFileInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
