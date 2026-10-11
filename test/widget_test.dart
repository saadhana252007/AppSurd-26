import 'package:flutter_test/flutter_test.dart';
import 'package:prooflock/app.dart';

void main() {
  testWidgets('PROOFLOCK app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProofLockApp());

    expect(find.text('PROOFLOCK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}