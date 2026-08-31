import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:basalt_server_management/ui/screens/dashboard_screen.dart';
import 'package:basalt_server_management/ui/screens/servers_screen.dart';
import 'package:basalt_server_management/ui/screens/settings_screen.dart';
import 'package:basalt_server_management/ui/screens/ssh_terminal_screen.dart';
import 'package:basalt_server_management/ui/widgets/server_card.dart';
import 'package:basalt_server_management/ui/widgets/flake_card.dart';
import 'package:basalt_server_management/ui/widgets/ssh_terminal_card.dart';
import 'package:basalt_server_management/services/ssh_service.dart';
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
    expect(find.byType(SshTerminalCard), findsOneWidget);
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

  testWidgets('ServersScreen renders Flakes, search bar, and cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flakes'), findsOneWidget);
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

  testWidgets('FlakeCard renders as a standalone widget and triggers callbacks', (WidgetTester tester) async {
    bool toggled = false;
    bool pinged = false;
    bool expanded = false;
    bool terminalOpened = false;

    const flake = Server(
      id: 'flake-test-1',
      name: 'API Flake',
      port: 5000,
      protocol: 'HTTP',
      status: ServerStatus.running,
      latencyMs: 12,
      latencyHistory: [10, 12, 14, 12],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlakeCard(
            flake: flake,
            isExpanded: true,
            onToggle: () => toggled = true,
            onPing: () => pinged = true,
            onExpandToggle: () => expanded = true,
            onOpenTerminal: () => terminalOpened = true,
          ),
        ),
      ),
    );

    expect(find.text('API Flake'), findsOneWidget);
    expect(find.text('HTTP'), findsOneWidget);
    expect(find.text('127.0.0.1:5000'), findsOneWidget);
    expect(find.text('12ms'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Ping'), findsOneWidget);
    expect(find.text('SSH\nTerminal'), findsOneWidget);

    // Tap Ping
    await tester.tap(find.text('Ping'));
    expect(pinged, isTrue);

    // Tap Pause/Resume
    await tester.tap(find.text('Pause'));
    expect(toggled, isTrue);

    // Tap Header
    await tester.tap(find.text('API Flake'));
    expect(expanded, isTrue);

    // Tap SSH Terminal tool
    await tester.tap(find.text('SSH\nTerminal'));
    expect(terminalOpened, isTrue);
  });

  testWidgets('SshTerminalCard renders dartssh2 header and controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SshTerminalCard(
            host: '127.0.0.1',
            username: 'andre',
            port: 22,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Host Terminal'), findsOneWidget);
    expect(find.text('(dartssh2)'), findsOneWidget);
    expect(find.text('andre@127.0.0.1:22'), findsOneWidget);
    expect(find.text('DISCONNECTED'), findsOneWidget);
    expect(find.text('uptime'), findsOneWidget);
    expect(find.text('Ctrl+C'), findsOneWidget);
    expect(find.text('Tab'), findsOneWidget);
    expect(find.text('ESC'), findsOneWidget);

    // Tap SSH Connection Settings button
    await tester.tap(find.byTooltip('SSH Connection Settings'));
    await tester.pumpAndSettle();

    expect(find.text('SSH Connection Settings'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Private Key (PEM)'), findsOneWidget);
  });

  testWidgets('SshTerminalScreen renders dedicated terminal view and shortcuts', (WidgetTester tester) async {
    final session = SshTerminalSession(
      config: const SshConfig(host: '192.168.1.100', port: 2222, username: 'root'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SshTerminalScreen(
          session: session,
          title: 'Remote SSH',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remote SSH'), findsOneWidget);
    expect(find.text('root@192.168.1.100:2222'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('Ctrl+C'), findsOneWidget);
    expect(find.text('Tab'), findsOneWidget);
    expect(find.text('ESC'), findsOneWidget);
    expect(find.text('▲ Up'), findsOneWidget);
    expect(find.text('▼ Down'), findsOneWidget);
    expect(find.text('uptime'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders SSH Client configuration section', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings & Configuration'), findsOneWidget);
    expect(find.text('SSH CLIENT ENGINE (DARTSSH2)'), findsOneWidget);
    expect(find.text('Default SSH Target'), findsOneWidget);
    expect(find.text('Launch SSH Terminal'), findsOneWidget);
    expect(find.text('Terminal Preferences'.toUpperCase()), findsOneWidget);
    expect(find.text('dartssh2 v4.0.0 (Pure Dart SSHv2 protocol)'), findsOneWidget);
  });

  test('SshTerminalSession unit tests', () {
    final session = SshTerminalSession(
      config: const SshConfig(host: '10.0.0.1', port: 22, username: 'admin'),
    );

    expect(session.config.summary, 'admin@10.0.0.1:22');
    expect(session.state, SshConnectionState.disconnected);
    expect(session.isConnected, isFalse);

    session.updateConfig(
      session.config.copyWith(username: 'operator', port: 2200),
    );
    expect(session.config.summary, 'operator@10.0.0.1:2200');

    // Test sending command when not connected writes error to terminal buffer
    session.sendCommand('uptime');
    expect(session.terminal.buffer.lines.length, greaterThan(0));

    // Test clear terminal
    session.clearTerminal();
  });
}
