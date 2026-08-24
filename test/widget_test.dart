import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:basalt_server_management/ui/screens/dashboard_screen.dart';
import 'package:basalt_server_management/ui/widgets/server_card.dart';
import 'package:basalt_server_management/models/server.dart';

void main() {
  testWidgets('DashboardScreen renders System metrics and Flakes Carousel', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Flakes'), findsOneWidget);
    expect(find.byType(CarouselSlider), findsOneWidget);
    expect(find.byType(ServerCard), findsWidgets);
    expect(find.text('Quick Port Matrix'), findsOneWidget);
  });

  testWidgets('ServerCard renders info and handles interactions', (WidgetTester tester) async {
    bool toggled = false;
    bool restarted = false;

    const server = Server(
      id: 'test-1',
      name: 'Test Server',
      port: 8080,
      status: ServerStatus.running,
      flakeType: 'Web API',
      flakeRef: 'flake:test#server',
      uptime: '1d 2h',
      cpuUsage: 12.0,
      memoryUsageString: '256 MB',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerCard.fromServer(
            server,
            onToggle: () => toggled = true,
            onRestart: () => restarted = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Server'), findsOneWidget);
    expect(find.text(':8080'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    // Tap Stop button
    await tester.tap(find.text('Stop'));
    expect(toggled, isTrue);

    // Tap Restart button
    await tester.tap(find.byTooltip('Restart Flake'));
    expect(restarted, isTrue);
  });

  testWidgets('DashboardScreen toggles server status on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stopButton = find.text('Stop').first;
    await tester.tap(stopButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}

