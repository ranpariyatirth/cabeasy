import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cabeasy/constants/app_colors.dart';
import 'package:cabeasy/models/request_model.dart';
import 'package:cabeasy/screens/registration_screen.dart';
import 'package:cabeasy/widgets/common/app_card.dart';
import 'package:cabeasy/widgets/common/gradient_button.dart';
import 'package:cabeasy/widgets/common/status_badge.dart';
import 'package:cabeasy/widgets/request/request_card.dart';

Future<void> _pumpForScenario(
  WidgetTester tester,
  Widget child, {
  required Size size,
  double textScale = 1.0,
}) async {
  await tester.binding.setSurfaceSize(size);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );

  await tester.pumpAndSettle();
  expect(
    tester.takeException(),
    isNull,
    reason: 'UI threw exception at size=$size textScale=$textScale',
  );

  final Finder scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    await tester.drag(scrollables.first, const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'UI threw exception while scrolling at size=$size textScale=$textScale',
    );
  }
}

Future<void> _runResponsiveScenarios(
  WidgetTester tester,
  Widget child,
) async {
  const List<Size> sizes = <Size>[
    Size(320, 568),
    Size(568, 320),
    Size(1024, 1366),
  ];

  for (final Size size in sizes) {
    await _pumpForScenario(tester, child, size: size, textScale: 1.0);
    await _pumpForScenario(tester, child, size: size, textScale: 1.3);
  }

  await tester.binding.setSurfaceSize(null);
}

void main() {
  group('Responsive UI safety', () {
    testWidgets('RegistrationScreen renders without overflow/exceptions', (
      WidgetTester tester,
    ) async {
      await _runResponsiveScenarios(
        tester,
        RegistrationScreen(),
      );
    });

    testWidgets('Shared card/button/badge widgets render safely', (
      WidgetTester tester,
    ) async {
      await _runResponsiveScenarios(
        tester,
        Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text('Card Title'),
                      SizedBox(height: 8),
                      Text('Card body sample text'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  onTap: null,
                  text: 'Action',
                  icon: Icons.check,
                ),
                const SizedBox(height: 12),
                const StatusBadge(status: 'open'),
                const SizedBox(height: 12),
                const StatusBadge(status: 'pending'),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('RequestCard handles long route/agent text safely', (
      WidgetTester tester,
    ) async {
      final RequestModel request = RequestModel(
        id: 'REQ-TEST-001',
        agentId: 'agent-1',
        agentName: 'Very Long Agent Name For Layout Verification',
        pickupLocation: 'Very Long Pickup Address Location Name, Terminal 1, International Airport',
        dropLocation: 'Very Long Drop Address Location Name, Hilltop Residency, Downtown Central District',
        travelDate: DateTime(2026, 2, 24, 14, 30),
        passengerCount: 12,
        vehicleType: 'tempo',
        notes: 'Test note',
        status: 'open',
        leadLevel: 'hot',
        createdAt: DateTime(2026, 2, 24, 11, 45),
        bidCount: 3,
      );

      await _runResponsiveScenarios(
        tester,
        Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[RequestCard(request: request)],
            ),
          ),
        ),
      );
    });
  });
}