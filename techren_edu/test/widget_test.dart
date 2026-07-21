import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techren_edu/app.dart';

void main() {
  testWidgets('App renders splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TechRenApp()));
    await tester.pump();

    expect(find.text('TechRen EDU'), findsOneWidget);
  });
}
