import '../errors/app_exception.dart';
import 'app_localizations.dart';

String localizedError(Object? error, AppLocalizations l10n, {bool forLogin = false}) {
  if (error is AppException) {
    return l10n.messageForError(code: error.code, fallback: error.message, forLogin: forLogin);
  }
  return l10n.messageForError(fallback: error?.toString(), forLogin: forLogin);
}
