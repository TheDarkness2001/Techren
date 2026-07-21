import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/learning_cms.dart';
import '../../domain/entities/words.dart';
import 'listening_provider.dart';
import 'sentences_provider.dart';
import 'words_provider.dart';

final cmsLanguagesProvider = FutureProvider.autoDispose<List<LearningLanguage>>((ref) async {
  return ref.watch(homeworkApiProvider).getLanguages();
});

final cmsLevelsProvider = FutureProvider.autoDispose.family<List<CmsLevel>, String>((ref, languageId) async {
  return ref.watch(homeworkApiProvider).getLevels(languageId);
});

final cmsLessonsProvider = FutureProvider.autoDispose.family<List<CmsLesson>, String>((ref, levelId) async {
  return ref.watch(homeworkApiProvider).getLessons(levelId);
});

final cmsLessonWordsProvider = FutureProvider.autoDispose.family<List<CmsWord>, String>((ref, lessonId) async {
  return ref.watch(homeworkApiProvider).getLessonWords(lessonId);
});

final cmsSentencesLanguagesProvider = FutureProvider.autoDispose<List<LearningLanguage>>((ref) async {
  return ref.watch(sentencesApiProvider).getCmsLanguages();
});

final cmsSentencesLevelsProvider = FutureProvider.autoDispose.family<List<CmsLevel>, String>((ref, languageId) async {
  return ref.watch(sentencesApiProvider).getCmsLevels(languageId);
});

final cmsSentencesLessonsProvider = FutureProvider.autoDispose.family<List<CmsLesson>, String>((ref, levelId) async {
  return ref.watch(sentencesApiProvider).getCmsLessons(levelId);
});

final cmsLessonSentencesProvider = FutureProvider.autoDispose.family<List<CmsSentence>, String>((ref, lessonId) async {
  return ref.watch(sentencesApiProvider).getLessonSentences(lessonId);
});

final cmsListeningLanguagesProvider = FutureProvider.autoDispose<List<LearningLanguage>>((ref) async {
  return ref.watch(listeningApiProvider).getCmsLanguages();
});

final cmsListeningLevelsProvider = FutureProvider.autoDispose.family<List<CmsLevel>, String>((ref, languageId) async {
  return ref.watch(listeningApiProvider).getCmsLevels(languageId);
});

final cmsListeningExercisesProvider = FutureProvider.autoDispose.family<List<CmsListeningExercise>, String>((ref, levelId) async {
  return ref.watch(listeningApiProvider).getLevelExercises(levelId);
});
