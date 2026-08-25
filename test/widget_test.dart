import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:basalt_server_management/ui/screens/dashboard_screen.dart';
import 'package:basalt_server_management/ui/screens/servers_screen.dart';
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
      flakeRef: '127.0.0.1:8080',
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
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    // Tap Stop button
    await tester.tap(find.text('Stop'));
    expect(toggled, isTrue);

    // Tap Restart button
    await tester.tap(find.byTooltip('Restart Flake'));
    expect(restarted, isTrue);
  });

  testWidgets('ServersScreen renders Flakes telemetry, search bar, and cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flakes'), findsOneWidget);
    expect(find.text('Total Flakes'), findsOneWidget);
    expect(find.text('Online'), findsWidgets);
    expect(find.text('Offline'), findsWidgets);
    expect(find.text('Avg Latency'), findsOneWidget);
    expect(find.text('Django API Server'), findsOneWidget);
    expect(find.text('Minecraft SMP Server'), findsOneWidget);
  });

  testWidgets('ServersScreen opens Add Flake modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.text('Add Flake'));
    await tester.pumpAndSettle();

    expect(find.text('Add Flake to Monitor'), findsOneWidget);
    expect(find.text('Quick Presets'), findsOneWidget);
  });

  testWidgets('ServersScreen opens Port Scanner modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap radar icon in AppBar
    await tester.tap(find.byTooltip('Scan Local Ports'));
    await tester.pumpAndSettle();

    expect(find.text('Local Port Scanner'), findsOneWidget);
    expect(find.text(':3000'), findsOneWidget);
  });
}
