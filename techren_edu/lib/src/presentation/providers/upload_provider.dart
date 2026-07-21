import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/upload_api.dart';
import '../../domain/entities/upload.dart';
import 'auth_provider.dart';

final uploadApiProvider = Provider<UploadApi>((ref) {
  return UploadApi(ref.watch(dioClientProvider));
});

final staffWordLessonsProvider = FutureProvider.autoDispose<List<StaffLessonOption>>((ref) async {
  return ref.watch(uploadApiProvider).getLessons('words');
});

final staffSentenceLessonsProvider = FutureProvider.autoDispose<List<StaffLessonOption>>((ref) async {
  return ref.watch(uploadApiProvider).getLessons('sentences');
});
