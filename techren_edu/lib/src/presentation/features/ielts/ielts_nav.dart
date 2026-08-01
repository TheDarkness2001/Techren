/// Shared IELTS path helpers — student uses `/learn`, staff uses `/learning`.
String ieltsLearnSegment(String routePrefix) =>
    routePrefix == '/student' ? 'learn' : 'learning';

String ieltsHubRoute(String routePrefix, String subjectId) =>
    '$routePrefix/${ieltsLearnSegment(routePrefix)}/$subjectId/ielts';

String ieltsSubjectHomeRoute(String routePrefix, String subjectId) =>
    '$routePrefix/${ieltsLearnSegment(routePrefix)}/$subjectId';
