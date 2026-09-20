import 'package:backoffice_web/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BackofficeApp renders dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(const BackofficeApp());

    expect(find.text('Lokalaku Backoffice Portal'), findsOneWidget);
    expect(find.text('Ringkasan Ekosistem Desa'), findsOneWidget);
  });
}
