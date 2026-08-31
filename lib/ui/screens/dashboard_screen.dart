import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/server.dart';
import '../widgets/resource_card.dart';
import '../widgets/server_card.dart';
import '../widgets/ssh_terminal_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentCarouselIndex = 0;

  final List<Server> _servers = [
    const Server(
      id: 'srv-1',
      name: 'Django API Server',
      host: '127.0.0.1',
      port: 8000,
      protocol: 'HTTP',
      status: ServerStatus.running,
      flakeType: 'Python Web API',
      flakeRef: '127.0.0.1:8000/health',
      healthPath: '/health',
      uptime: '4d 12h',
      cpuUsage: 14.2,
      memoryUsagePercent: 18.0,
      memoryUsageString: '384 MB',
      networkSpeed: '450 KB/s',
      icon: Icons.webhook_rounded,
      environment: 'Production',
      latencyMs: 14,
      statusMessage: '200 OK — Healthy',
    ),
    const Server(
      id: 'srv-2',
      name: 'Minecraft SMP Server',
      host: 'localhost',
      port: 25565,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'Game Server',
      flakeRef: 'localhost:25565',
      healthPath: '',
      uptime: '2d 08h',
      cpuUsage: 38.5,
      memoryUsagePercent: 60.0,
      memoryUsageString: '2.4 GB',
      networkSpeed: '1.8 MB/s',
      icon: Icons.sports_esports_rounded,
      environment: 'Production',
      latencyMs: 28,
      statusMessage: 'Socket Connected — 12 Players',
    ),
    const Server(
      id: 'srv-3',
      name: 'PostgreSQL Database',
      host: '127.0.0.1',
      port: 5432,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'SQL Database',
      flakeRef: '127.0.0.1:5432',
      healthPath: '',
      uptime: '14d 06h',
      cpuUsage: 6.8,
      memoryUsagePercent: 25.0,
      memoryUsageString: '512 MB',
      networkSpeed: '120 KB/s',
      icon: Icons.storage_rounded,
      environment: 'Production',
      latencyMs: 4,
      statusMessage: 'TCP Handshake OK',
    ),
    const Server(
      id: 'srv-4',
      name: 'Redis Cache',
      host: '127.0.0.1',
      port: 6379,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'In-Memory Store',
      flakeRef: '127.0.0.1:6379',
      healthPath: '',
      uptime: '14d 06h',
      cpuUsage: 1.5,
      memoryUsagePercent: 12.0,
      memoryUsageString: '128 MB',
      networkSpeed: '240 KB/s',
      icon: Icons.memory_rounded,
      environment: 'Production',
      latencyMs: 2,
      statusMessage: 'PONG Response',
    ),
    const Server(
      id: 'srv-5',
      name: 'Next.js Frontend',
      host: 'localhost',
      port: 3000,
      protocol: 'HTTP',
      status: ServerStatus.stopped,
      flakeType: 'Web Client',
      flakeRef: 'localhost:3000',
      healthPath: '/',
      uptime: 'Offline',
      cpuUsage: 0.0,
      memoryUsagePercent: 0.0,
      memoryUsageString: '0 MB',
      networkSpeed: '0 KB/s',
      icon: Icons.devices_rounded,
      environment: 'Development',
      latencyMs: 0,
      statusMessage: 'Connection Refused',
    ),
    const Server(
      id: 'srv-6',
      name: 'Prometheus & Grafana',
      host: '127.0.0.1',
      port: 9090,
      protocol: 'HTTP',
      status: ServerStatus.stopped,
      flakeType: 'Telemetry Stack',
      flakeRef: '127.0.0.1:9090/-/healthy',
      healthPath: '/-/healthy',
      uptime: 'Offline',
      cpuUsage: 0.0,
      memoryUsagePercent: 0.0,
      memoryUsageString: '0 MB',
      networkSpeed: '0 KB/s',
      icon: Icons.insights_rounded,
      environment: 'Staging',
      latencyMs: 0,
      statusMessage: 'Port inactive',
    ),
  ];

  void _toggleServer(int index) {
    setState(() {
      final s = _servers[index];
      final newStatus = s.isRunning ? ServerStatus.stopped : ServerStatus.running;
      _servers[index] = s.copyWith(
        status: newStatus,
        uptime: newStatus == ServerStatus.running ? 'Just started' : 'Offline',
        cpuUsage: newStatus == ServerStatus.running ? 8.0 : 0.0,
        memoryUsageString: newStatus == ServerStatus.running ? '210 MB' : '0 MB',
        latencyMs: newStatus == ServerStatus.running ? 14 : 0,
      );
    });

    final s = _servers[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.isRunning
              ? '${s.name} monitoring started on port ${s.port}'
              : '${s.name} monitoring paused',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restartServer(int index) {
    final s = _servers[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking socket connectivity for ${s.name}...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _servers[index] = s.copyWith(uptime: 'Checked just now');
    });
  }

  void _showTerminalLogs(Server server) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${server.name} — Port Telemetry',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Address: ${server.host}:${server.port}${server.healthPath} • ${server.protocol}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.outline,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildLogLine('[basalt-monitor] Polling socket ${server.host}:${server.port}...', Colors.blueAccent),
                          _buildLogLine('[basalt-probe] Protocol: ${server.protocol} probe dispatched', Colors.grey),
                          if (server.isRunning) ...[
                            _buildLogLine('[basalt-probe] Connection established in ${server.latencyMs}ms', Colors.greenAccent),
                            _buildLogLine('[health] Status 200 OK — Socket live', Colors.cyanAccent),
                            _buildLogLine('[telemetry] CPU: ${server.cpuUsage}% | Memory: ${server.memoryUsageString}', Colors.amberAccent),
                            _buildLogLine('[telemetry] Network throughput: ${server.networkSpeed}', Colors.white70),
                          ] else ...[
                            _buildLogLine('[basalt-probe] Connection refused: Port ${server.port} closed or paused', Colors.redAccent),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final runningCount = _servers.where((s) => s.isRunning).length;

    return Container(
      color: colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Metrics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'System',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: Colors.greenAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Healthy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ResourceCard(
                    title: 'CPU',
                    value: '23',
                    data: [10, 14, 12, 20, 50, 23],
                  ),
                  ResourceCard(
                    title: 'MEM',
                    value: '80',
                    data: [60, 65, 70, 75, 78, 80],
                  ),
                  ResourceCard(
                    title: 'NET',
                    value: '0.5',
                    data: [0.2, 0.4, 0.3, 0.8, 0.6, 0.5],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Flakes Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Flakes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$runningCount/${_servers.length} Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Carousel navigation arrows
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: 'Previous Flake',
                        onPressed: () => _carouselController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: 'Next Flake',
                        onPressed: () => _carouselController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Server Flakes Carousel Slider
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: _servers.length,
              options: CarouselOptions(
                height: 220,
                viewportFraction: 0.90,
                enlargeCenterPage: true,
                enlargeFactor: 0.16,
                enableInfiniteScroll: true,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final server = _servers[index];
                return ServerCard.fromServer(
                  server,
                  onToggle: () => _toggleServer(index),
                  onRestart: () => _restartServer(index),
                  onTerminal: () => _showTerminalLogs(server),
                  onTap: () => _showTerminalLogs(server),
                );
              },
            ),

            const SizedBox(height: 12),

            // Animated Carousel Indicator Dots
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_servers.length, (index) {
                  final isSelected = _currentCarouselIndex == index;
                  final isRunning = _servers[index].isRunning;

                  return GestureDetector(
                    onTap: () => _carouselController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isRunning ? colors.primary : Colors.redAccent)
                            : colors.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Host SSH Terminal
            const SshTerminalCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
