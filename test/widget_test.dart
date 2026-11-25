import 'package:flutter_test/flutter_test.dart';
import 'package:pc_rig_builder/main.dart';

void main() {
  testWidgets('PC Rig Builder App loads dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('PC Rig Builder'), findsWidgets);
  });
}
