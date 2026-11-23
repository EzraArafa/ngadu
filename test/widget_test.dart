import 'package:flutter_test/flutter_test.dart';

import 'package:ngadu/main.dart';

void main() {
  testWidgets('Splash screen menampilkan logo NGADU', (tester) async {
    await tester.pumpWidget(const NgaduApp());
    expect(find.text('NGADU'), findsOneWidget);
    // Habiskan timer splash 600ms
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
  });
}
