import '../constants/api_constants.dart';

String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = Uri.parse(ApiConstants.baseUrl);
  final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '$origin$path';
}
