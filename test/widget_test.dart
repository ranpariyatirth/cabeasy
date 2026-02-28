import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cabeasy/screens/registration_screen.dart';

void main() {
  testWidgets('Registration screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: RegistrationScreen()));

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
