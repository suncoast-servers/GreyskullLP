import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greyskull_lp/main.dart';

void main() {
  testWidgets('Greyskull app boots and shows splash',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GreyskullApp());
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
