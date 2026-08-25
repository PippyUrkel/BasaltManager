import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/server.dart';
import '../../models/port.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  // Track which flake's toolbox is expanded
  String? _expandedFlakeId;

  final List<Server> _flakes = [
    const Server(
      id: 'flake-1',
      name: 'Django API Server',
      host: '127.0.0.1',
      port: 8000,
      protocol: 'HTTP',
      status: ServerStatus.running,
      flakeType: 'Web API',
      flakeRef: '127.0.0.1:8000/health',
      healthPath: '/health',
      checkIntervalSec: 10,
      latencyMs: 14,
      uptimePercentage: 99.98,
      latencyHistory: [12, 14, 18, 15, 12, 16, 14, 13, 17, 12, 14, 15],
      uptime: '4d 12h',
      cpuUsage: 14.2,
      memoryUsageString: '384 MB',
      networkSpeed: '450 KB/s',
      icon: Icons.webhook_rounded,
      environment: 'Production',
      statusMessage: '200 OK — Healthy',
    ),
    const Server(
      id: 'flake-2',
      name: 'Minecraft SMP Server',
      host: 'localhost',
      port: 25565,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'Game Server',
      flakeRef: 'localhost:25565',
      healthPath: '',
      checkIntervalSec: 15,
      latencyMs: 28,
      uptimePercentage: 99.4,
      latencyHistory: [25, 30, 28, 35, 29, 27, 28, 32, 26, 31, 29, 28],
      uptime: '2d 08h',
      cpuUsage: 38.5,
      memoryUsageString: '2.4 GB',
      networkSpeed: '1.8 MB/s',
      icon: Icons.sports_esports_rounded,
      environment: 'Production',
      statusMessage: 'Socket Connected — 12 Players',
    ),
    const Server(
      id: 'flake-3',
      name: 'PostgreSQL Database',
      host: '127.0.0.1',
      port: 5432,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'SQL Database',
      flakeRef: '127.0.0.1:5432',
      healthPath: '',
      checkIntervalSec: 30,
      latencyMs: 4,
      uptimePercentage: 100.0,
      latencyHistory: [3, 4, 4, 5, 4, 4, 4, 3, 5, 4, 4, 3],
      uptime: '14d 06h',
      cpuUsage: 6.8,
      memoryUsageString: '512 MB',
      networkSpeed: '120 KB/s',
      icon: Icons.storage_rounded,
      environment: 'Production',
      statusMessage: 'TCP Handshake OK — 8 Connections',
    ),
    const Server(
      id: 'flake-4',
      name: 'Redis Cache',
      host: '127.0.0.1',
      port: 6379,
      protocol: 'TCP',
      status: ServerStatus.running,
      flakeType: 'In-Memory Store',
      flakeRef: '127.0.0.1:6379',
      healthPath: '',
      checkIntervalSec: 15,
      latencyMs: 2,
      uptimePercentage: 100.0,
      latencyHistory: [2, 2, 3, 2, 2, 2, 2, 1, 3, 2, 2, 2],
      uptime: '14d 06h',
      cpuUsage: 1.5,
      memoryUsageString: '128 MB',
      networkSpeed: '240 KB/s',
      icon: Icons.memory_rounded,
      environment: 'Production',
      statusMessage: 'PONG Response (2ms)',
    ),
    const Server(
      id: 'flake-5',
      name: 'Next.js Frontend',
      host: 'localhost',
      port: 3000,
      protocol: 'HTTP',
      status: ServerStatus.stopped,
      flakeType: 'Web Client',
      flakeRef: 'localhost:3000',
      healthPath: '/',
      checkIntervalSec: 15,
      latencyMs: 0,
      uptimePercentage: 92.5,
      latencyHistory: [18, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      uptime: 'Offline',
      cpuUsage: 0.0,
      memoryUsageString: '0 MB',
      networkSpeed: '0 KB/s',
      icon: Icons.devices_rounded,
      environment: 'Development',
      statusMessage: 'Connection Refused (Port Closed)',
    ),
    const Server(
      id: 'flake-6',
      name: 'Prometheus Telemetry',
      host: '127.0.0.1',
      port: 9090,
      protocol: 'HTTP',
      status: ServerStatus.stopped,
      flakeType: 'Metrics Stack',
      flakeRef: '127.0.0.1:9090/-/healthy',
      healthPath: '/-/healthy',
      checkIntervalSec: 60,
      latencyMs: 0,
      uptimePercentage: 94.2,
      latencyHistory: [8, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      uptime: 'Offline',
      cpuUsage: 0.0,
      memoryUsageString: '0 MB',
      networkSpeed: '0 KB/s',
      icon: Icons.insights_rounded,
      environment: 'Staging',
      statusMessage: 'Port inactive',
    ),
  ];

  final Set<String> _pingingFlakeIds = {};

  List<Server> get _filteredFlakes {
    return _flakes.where((flake) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = flake.name.toLowerCase().contains(q) ||
          flake.port.toString().contains(_searchQuery) ||
          flake.host.toLowerCase().contains(q) ||
          flake.flakeType.toLowerCase().contains(q);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Online') return flake.isRunning;
      if (_selectedFilter == 'Offline') return !flake.isRunning;
      if (_selectedFilter == 'HTTP/S') {
        return flake.protocol == 'HTTP' || flake.protocol == 'HTTPS';
      }
      if (_selectedFilter == 'TCP/Socket') return flake.protocol == 'TCP';

      return true;
    }).toList();
  }

  void _toggleFlakeMonitoring(int index) {
    setState(() {
      final flake = _flakes[index];
      final newStatus =
          flake.isRunning ? ServerStatus.stopped : ServerStatus.running;
      _flakes[index] = flake.copyWith(
        status: newStatus,
        uptime: newStatus == ServerStatus.running ? 'Just now' : 'Offline',
        latencyMs: newStatus == ServerStatus.running ? 16 : 0,
        statusMessage: newStatus == ServerStatus.running
            ? 'Monitored & Healthy'
            : 'Monitoring Paused',
      );
    });

    final flake = _flakes[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          flake.isRunning
              ? 'Monitoring resumed for ${flake.name} (Port ${flake.port})'
              : 'Monitoring paused for ${flake.name}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pingFlake(Server flake) async {
    setState(() {
      _pingingFlakeIds.add(flake.id);
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final index = _flakes.indexWhere((f) => f.id == flake.id);
    if (index != -1) {
      final newLatency = flake.isRunning ? 12 + (index * 3) : 0;
      setState(() {
        _flakes[index] = flake.copyWith(
          latencyMs: newLatency,
          statusMessage: flake.isRunning
              ? 'Ping response: ${newLatency}ms'
              : 'Port unreachable',
        );
        _pingingFlakeIds.remove(flake.id);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          flake.isRunning
              ? '⚡ ${flake.name} responded in ${flake.latencyMs}ms'
              : '❌ ${flake.name} (Port ${flake.port}) is unreachable',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteFlake(int index) {
    final deleted = _flakes[index];
    setState(() {
      _flakes.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${deleted.name} from Flakes monitor'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _flakes.insert(index, deleted);
            });
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────────────────── Add Flake Modal ─────────────────────────────

  void _showAddFlakeModal() {
    final nameCtrl = TextEditingController();
    final hostCtrl = TextEditingController(text: '127.0.0.1');
    final portCtrl = TextEditingController();
    final pathCtrl = TextEditingController(text: '/health');
    String selectedProtocol = 'HTTP';
    String selectedCategory = 'Web API';
    int checkInterval = 15;
    IconData selectedIcon = Icons.dns_rounded;

    final List<Map<String, dynamic>> portPresets = [
      {'name': 'Django / FastAPI', 'port': 8000, 'proto': 'HTTP', 'icon': Icons.webhook_rounded, 'cat': 'Web API'},
      {'name': 'React / Next.js', 'port': 3000, 'proto': 'HTTP', 'icon': Icons.devices_rounded, 'cat': 'Frontend'},
      {'name': 'Spring / Tomcat', 'port': 8080, 'proto': 'HTTP', 'icon': Icons.api_rounded, 'cat': 'Web API'},
      {'name': 'PostgreSQL', 'port': 5432, 'proto': 'TCP', 'icon': Icons.storage_rounded, 'cat': 'SQL Database'},
      {'name': 'Redis Cache', 'port': 6379, 'proto': 'TCP', 'icon': Icons.memory_rounded, 'cat': 'In-Memory Store'},
      {'name': 'Minecraft Server', 'port': 25565, 'proto': 'TCP', 'icon': Icons.sports_esports_rounded, 'cat': 'Game Server'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add_circle_outline_rounded,
                              color: colors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Flake to Monitor',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Configure server host & port telemetry',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Port Presets
                    const Text(
                      'Quick Presets',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: portPresets.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(preset['icon'] as IconData,
                                  size: 14),
                              label: Text(
                                  '${preset['name']} :${preset['port']}'),
                              onPressed: () {
                                setModalState(() {
                                  nameCtrl.text = preset['name'] as String;
                                  portCtrl.text =
                                      preset['port'].toString();
                                  selectedProtocol =
                                      preset['proto'] as String;
                                  selectedIcon =
                                      preset['icon'] as IconData;
                                  selectedCategory =
                                      preset['cat'] as String;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Input
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Flake / Server Name',
                        hintText: 'e.g. Auth Microservice',
                        prefixIcon:
                            const Icon(Icons.label_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Host & Port Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: hostCtrl,
                            decoration: InputDecoration(
                              labelText: 'Host / IP',
                              hintText: '127.0.0.1',
                              prefixIcon:
                                  const Icon(Icons.computer_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: portCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Port *',
                              hintText: '8080',
                              prefixIcon:
                                  const Icon(Icons.lan_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Protocol & Health Path Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedProtocol,
                            decoration: InputDecoration(
                              labelText: 'Protocol',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                            ),
                            items: [
                              'HTTP',
                              'HTTPS',
                              'TCP',
                              'WebSocket',
                              'UDP'
                            ].map((p) {
                              return DropdownMenuItem(
                                  value: p, child: Text(p));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(
                                    () => selectedProtocol = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: pathCtrl,
                            decoration: InputDecoration(
                              labelText: 'Health Check Path',
                              hintText: '/health',
                              prefixIcon:
                                  const Icon(Icons.route_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Check Interval
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Polling Interval',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Every ${checkInterval}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: checkInterval.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '${checkInterval}s',
                      onChanged: (val) {
                        setModalState(
                            () => checkInterval = val.round());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_task_rounded),
                        label:
                            const Text('Add & Start Monitoring Flake'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final port =
                              int.tryParse(portCtrl.text.trim());
                          if (port == null ||
                              port <= 0 ||
                              port > 65535) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter a valid port number (1-65535)')),
                            );
                            return;
                          }

                          final flakeName =
                              nameCtrl.text.trim().isNotEmpty
                                  ? nameCtrl.text.trim()
                                  : 'Flake :$port';

                          final newFlake = Server(
                            id: 'flake-${DateTime.now().millisecondsSinceEpoch}',
                            name: flakeName,
                            host: hostCtrl.text.trim().isNotEmpty
                                ? hostCtrl.text.trim()
                                : '127.0.0.1',
                            port: port,
                            protocol: selectedProtocol,
                            status: ServerStatus.running,
                            flakeType: selectedCategory,
                            flakeRef:
                                '${hostCtrl.text.trim()}:$port${pathCtrl.text.trim()}',
                            healthPath: pathCtrl.text.trim(),
                            checkIntervalSec: checkInterval,
                            latencyMs: 12,
                            uptimePercentage: 100.0,
                            latencyHistory: const [
                              10, 12, 15, 11, 14, 12, 12, 13, 11, 14,
                              12, 10
                            ],
                            uptime: 'Just added',
                            cpuUsage: 5.0,
                            memoryUsageString: '128 MB',
                            networkSpeed: '50 KB/s',
                            icon: selectedIcon,
                            environment: 'Local',
                            statusMessage: 'Active & Responding',
                          );

                          setState(() {
                            _flakes.insert(0, newFlake);
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added ${newFlake.name} on port ${newFlake.port}!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────── Port Scanner Modal ───────────────────────────

  void _showPortScannerModal() {
    final List<MonitoredPort> detectedPorts = [
      const MonitoredPort(
          port: 3000,
          serviceName: 'Node.js Express Server',
          protocol: 'HTTP',
          processName: 'node',
          pid: 4821),
      const MonitoredPort(
          port: 5432,
          serviceName: 'PostgreSQL Database',
          protocol: 'TCP',
          processName: 'postgres',
          pid: 1102),
      const MonitoredPort(
          port: 6379,
          serviceName: 'Redis Server',
          protocol: 'TCP',
          processName: 'redis-server',
          pid: 981),
      const MonitoredPort(
          port: 8000,
          serviceName: 'Python Gunicorn / Django',
          protocol: 'HTTP',
          processName: 'gunicorn',
          pid: 5409),
      const MonitoredPort(
          port: 8080,
          serviceName: 'Local Proxy / Gateway',
          protocol: 'HTTP',
          processName: 'caddy',
          pid: 2198),
      const MonitoredPort(
          port: 27017,
          serviceName: 'MongoDB Daemon',
          protocol: 'TCP',
          processName: 'mongod',
          pid: 1420),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Local Port Scanner',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Discovered listening sockets on localhost (127.0.0.1)',
                style:
                    TextStyle(fontSize: 12, color: colors.outline),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: detectedPorts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = detectedPorts[i];
                    final alreadyMonitored =
                        _flakes.any((f) => f.port == item.port);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ':${item.port}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: colors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        item.serviceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      subtitle: Text(
                        '${item.protocol} • Process: ${item.processName} (PID ${item.pid})',
                        style: TextStyle(
                            fontSize: 12, color: colors.outline),
                      ),
                      trailing: alreadyMonitored
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Monitored',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity:
                                    VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10),
                              ),
                              onPressed: () {
                                final newFlake = Server(
                                  id: 'flake-${DateTime.now().millisecondsSinceEpoch}',
                                  name: item.serviceName,
                                  host: '127.0.0.1',
                                  port: item.port,
                                  protocol: item.protocol,
                                  status: ServerStatus.running,
                                  flakeType:
                                      item.protocol == 'HTTP'
                                          ? 'Web API'
                                          : 'TCP Service',
                                  flakeRef:
                                      '127.0.0.1:${item.port}',
                                  uptime: 'Just added',
                                  latencyMs: 8,
                                  uptimePercentage: 100.0,
                                );
                                setState(() {
                                  _flakes.insert(0, newFlake);
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Added ${item.serviceName} (:${item.port}) to Flakes!')),
                                );
                              },
                              child: const Text('Add Flake'),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────── Per-Flake Tools ─────────────────────────────

  void _showFlakeTraceroute(Server flake) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final hops = [
          {'hop': 1, 'host': '127.0.0.1', 'ms': '0.04'},
          {'hop': 2, 'host': '192.168.1.1', 'ms': '1.23'},
          {'hop': 3, 'host': '10.0.0.1', 'ms': '3.87'},
          {'hop': 4, 'host': flake.host, 'ms': '${flake.latencyMs}.00'},
        ];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.route_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Traceroute to ${flake.host}:${flake.port}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ...hops.map((hop) {
                final isLast = hop == hops.last;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Column(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLast
                                    ? colors.primary.withValues(alpha: 0.2)
                                    : colors.surfaceContainerHighest,
                                border: Border.all(
                                  color: isLast
                                      ? colors.primary
                                      : colors.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${hop['hop']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLast
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${hop['host']}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${hop['ms']} ms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.outline,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFlakeConnectionLog(Server flake) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final logEntries = flake.isRunning
            ? [
                _LogEntry('INFO', 'Socket opened to ${flake.host}:${flake.port}', '00:00:01'),
                _LogEntry('OK', '${flake.protocol} handshake complete', '00:00:02'),
                _LogEntry('OK', 'Health check → 200 OK (${flake.latencyMs}ms)', '00:00:03'),
                _LogEntry('INFO', 'TLS: N/A (plain ${flake.protocol})', '00:00:03'),
                _LogEntry('OK', 'Keepalive ping → PONG', '00:00:14'),
                _LogEntry('INFO', 'Next probe in ${flake.checkIntervalSec}s', '00:00:14'),
              ]
            : [
                _LogEntry('INFO', 'Attempting socket to ${flake.host}:${flake.port}', '00:00:01'),
                _LogEntry('ERR', 'Connection refused: port ${flake.port} closed', '00:00:02'),
                _LogEntry('WARN', 'Retrying in ${flake.checkIntervalSec}s...', '00:00:02'),
              ];

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, scroll) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${flake.name} — Connection Log',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ListView.builder(
                        controller: scroll,
                        itemCount: logEntries.length,
                        itemBuilder: (_, i) {
                          final entry = logEntries[i];
                          final color = switch (entry.level) {
                            'OK' => const Color(0xFF4CAF50),
                            'ERR' => const Color(0xFFEF5350),
                            'WARN' => Colors.amberAccent,
                            _ => const Color(0xFF64B5F6),
                          };
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    entry.time,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: colors.outline,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    entry.level,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.message,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: color.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

  void _showFlakeHeaders(Server flake) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final headers = flake.protocol == 'HTTP' || flake.protocol == 'HTTPS'
            ? {
                'HTTP/1.1': flake.isRunning ? '200 OK' : '— Connection Refused',
                'Content-Type': 'application/json; charset=utf-8',
                'Server': flake.flakeType,
                'X-Response-Time': '${flake.latencyMs}ms',
                'Connection': 'keep-alive',
                'X-Basalt-Flake': flake.id,
              }
            : {
                'Protocol': flake.protocol,
                'Socket State': flake.isRunning ? 'ESTABLISHED' : 'CLOSED',
                'Remote': '${flake.host}:${flake.port}',
                'Latency': '${flake.latencyMs}ms',
                'X-Basalt-Flake': flake.id,
              };

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.code_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Response Headers',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headers.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                          children: [
                            TextSpan(
                              text: '${e.key}: ',
                              style:
                                  TextStyle(color: colors.primary),
                            ),
                            TextSpan(
                              text: e.value,
                              style: const TextStyle(
                                  color: Color(0xFFE0E0E0)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // cURL preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'curl -I ${flake.protocol.toLowerCase()}://${flake.host}:${flake.port}${flake.healthPath}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF81C784),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════ BUILD ═════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalCount = _flakes.length;
    final onlineCount = _flakes.where((f) => f.isRunning).length;
    final offlineCount = totalCount - onlineCount;
    final filteredList = _filteredFlakes;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.storage_rounded, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Flakes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar_rounded),
            tooltip: 'Scan Local Ports',
            onPressed: _showPortScannerModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFlakeModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Flake'),
      ),
      body: CustomScrollView(
        slivers: [

          // ─── Search & Filter ───
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search flakes',
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Online',
                        'Offline',
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Empty State ───
          if (filteredList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied_rounded,
                        size: 56, color: colors.outline.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No Flakes found',
                      style: TextStyle(
                          fontSize: 16,
                          color: colors.outline,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try adjusting your search or add a new port to monitor.',
                      style:
                          TextStyle(fontSize: 12, color: colors.outline),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add First Flake'),
                      onPressed: _showAddFlakeModal,
                    ),
                  ],
                ),
              ),
            )
          else
            // ─── Flake Cards ───
            SliverPadding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final flake = filteredList[index];
                    final realIndex = _flakes.indexOf(flake);
                    final isPinging =
                        _pingingFlakeIds.contains(flake.id);

                    return _FlakeCard(
                      flake: flake,
                      isPinging: isPinging,
                      isExpanded: _expandedFlakeId == flake.id,
                      onToggle: () =>
                          _toggleFlakeMonitoring(realIndex),
                      onPing: () => _pingFlake(flake),
                      onDelete: () => _deleteFlake(realIndex),
                      onExpandToggle: () {
                        setState(() {
                          _expandedFlakeId =
                              _expandedFlakeId == flake.id
                                  ? null
                                  : flake.id;
                        });
                      },
                      onShowLog: () =>
                          _showFlakeConnectionLog(flake),
                      onShowTrace: () =>
                          _showFlakeTraceroute(flake),
                      onShowHeaders: () =>
                          _showFlakeHeaders(flake),
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _calculateAvgLatency() {
    final active =
        _flakes.where((f) => f.isRunning && f.latencyMs > 0).toList();
    if (active.isEmpty) return 0;
    final sum = active.fold<int>(0, (prev, f) => prev + f.latencyMs);
    return (sum / active.length).round();
  }

  Widget _buildSummaryCard({
    required ColorScheme colors,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  colors.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 10, color: colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ FLAKE CARD WIDGET ═══════════════════════════════════

class _FlakeCard extends StatelessWidget {
  final Server flake;
  final bool isPinging;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onPing;
  final VoidCallback onDelete;
  final VoidCallback onExpandToggle;
  final VoidCallback onShowLog;
  final VoidCallback onShowTrace;
  final VoidCallback onShowHeaders;

  const _FlakeCard({
    required this.flake,
    required this.isPinging,
    required this.isExpanded,
    required this.onToggle,
    required this.onPing,
    required this.onDelete,
    required this.onExpandToggle,
    required this.onShowLog,
    required this.onShowTrace,
    required this.onShowHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRunning = flake.isRunning;

    // Flake visual accents — crystalline feel
    final borderColor = isRunning
        ? colors.primary.withValues(alpha: 0.4)
        : colors.outlineVariant.withValues(alpha: 0.25);
    final glowColor = isRunning
        ? colors.primary.withValues(alpha: 0.06)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: glowColor,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: isRunning ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          color: isRunning
              ? colors.surfaceContainerHigh
              : colors.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ─── Main card body ───
              InkWell(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                onTap: onExpandToggle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Row 1: Identity
                      Row(
                        children: [
                          // Flake crystal icon
                          _FlakeAvatar(
                            icon: flake.icon,
                            isRunning: isRunning,
                            colors: colors,
                          ),
                          const SizedBox(width: 14),

                          // Name + address
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        flake.name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Protocol pill
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        flake.protocol,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: colors
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Address
                                    Flexible(
                                      child: Text(
                                        '${flake.host}:${flake.port}',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: colors.outline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Status + latency column
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              _StatusChip(isRunning: isRunning, colors: colors),
                              if (isRunning) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${flake.latencyMs}ms',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: _latencyColor(flake.latencyMs),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Row 2: Sparkline + quick stats
                      Row(
                        children: [
                          // Latency sparkline
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 36,
                              child: _LatencySparkline(
                                data: flake.latencyHistory,
                                isRunning: isRunning,
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Stat pills
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                _MiniStat(
                                  label: flake.uptime,
                                  icon: Icons.schedule_rounded,
                                  colors: colors,
                                ),
                                const SizedBox(width: 6),
                                _MiniStat(
                                  label:
                                      '${flake.uptimePercentage.toStringAsFixed(1)}%',
                                  icon: Icons.trending_up_rounded,
                                  colors: colors,
                                  highlight: flake.uptimePercentage >= 99.9,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Row 3: Quick actions strip
                      Row(
                        children: [
                          // Ping button
                          _FlakeActionButton(
                            icon: isPinging
                                ? null
                                : Icons.bolt_rounded,
                            label: isPinging ? 'Pinging...' : 'Ping',
                            isPinging: isPinging,
                            onPressed: isPinging ? null : onPing,
                            colors: colors,
                            filled: true,
                          ),
                          const SizedBox(width: 8),
                          // Monitoring toggle
                          _FlakeActionButton(
                            icon: isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            label: isRunning ? 'Pause' : 'Resume',
                            onPressed: onToggle,
                            colors: colors,
                          ),
                          const Spacer(),
                          // Expand toolbox
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 22,
                              color: colors.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Expandable Toolbox ───
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _FlakeToolbox(
                  flake: flake,
                  colors: colors,
                  onShowLog: onShowLog,
                  onShowTrace: onShowTrace,
                  onShowHeaders: onShowHeaders,
                  onDelete: onDelete,
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _latencyColor(int ms) {
    if (ms <= 10) return const Color(0xFF4CAF50);
    if (ms <= 30) return const Color(0xFF81C784);
    if (ms <= 80) return Colors.amberAccent;
    return const Color(0xFFEF5350);
  }
}

// ═══════════════════════ SUBWIDGETS ═════════════════════════════════════════

/// The crystalline hexagonal avatar for each flake
class _FlakeAvatar extends StatelessWidget {
  final IconData icon;
  final bool isRunning;
  final ColorScheme colors;

  const _FlakeAvatar({
    required this.icon,
    required this.isRunning,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexagonPainter(
        fillColor: isRunning
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surfaceContainerHighest,
        borderColor: isRunning
            ? colors.primary.withValues(alpha: 0.5)
            : colors.outlineVariant.withValues(alpha: 0.4),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isRunning ? colors.primary : colors.outline,
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _HexagonPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1.5;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_HexagonPainter old) =>
      old.fillColor != fillColor || old.borderColor != borderColor;
}

/// Status chip (ONLINE / OFFLINE)
class _StatusChip extends StatelessWidget {
  final bool isRunning;
  final ColorScheme colors;

  const _StatusChip({required this.isRunning, required this.colors});

  @override
  Widget build(BuildContext context) {
    final color =
        isRunning ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: isRunning
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isRunning ? 'LIVE' : 'DOWN',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Latency sparkline using fl_chart
class _LatencySparkline extends StatelessWidget {
  final List<double> data;
  final bool isRunning;
  final ColorScheme colors;

  const _LatencySparkline({
    required this.data,
    required this.isRunning,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final lineColor = isRunning ? colors.primary : colors.outline.withValues(alpha: 0.4);
    final maxY = data.reduce(math.max);
    final safeMax = maxY == 0 ? 1.0 : maxY;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 1.8,
            color: lineColor,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) {
                if (spot.x == data.length - 1) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 0,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.08),
            ),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: 0,
        maxY: safeMax * 1.3,
      ),
    );
  }
}

/// Small stat pill
class _MiniStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colors;
  final bool highlight;

  const _MiniStat({
    required this.label,
    required this.icon,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: highlight
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: highlight
              ? Border.all(
                  color: colors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: highlight
                    ? colors.primary
                    : colors.outline),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small action button used in the flake card
class _FlakeActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isPinging;
  final VoidCallback? onPressed;
  final ColorScheme colors;
  final bool filled;

  const _FlakeActionButton({
    this.icon,
    required this.label,
    this.isPinging = false,
    this.onPressed,
    required this.colors,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        height: 32,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
          icon: isPinging
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 16),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
              color: colors.outlineVariant
                  .withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}

// ═══════════════════════ EXPANDABLE TOOLBOX ═════════════════════════════════

class _FlakeToolbox extends StatelessWidget {
  final Server flake;
  final ColorScheme colors;
  final VoidCallback onShowLog;
  final VoidCallback onShowTrace;
  final VoidCallback onShowHeaders;
  final VoidCallback onDelete;

  const _FlakeToolbox({
    required this.flake,
    required this.colors,
    required this.onShowLog,
    required this.onShowTrace,
    required this.onShowHeaders,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbox header
          Row(
            children: [
              Icon(Icons.build_circle_outlined,
                  size: 14, color: colors.outline),
              const SizedBox(width: 6),
              Text(
                'MONITORING TOOLS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: colors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tool grid
          Row(
            children: [
              Expanded(
                child: _ToolTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Connection\nLog',
                  colors: colors,
                  onTap: onShowLog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolTile(
                  icon: Icons.route_rounded,
                  label: 'Trace\nRoute',
                  colors: colors,
                  onTap: onShowTrace,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolTile(
                  icon: Icons.code_rounded,
                  label: 'Response\nHeaders',
                  colors: colors,
                  onTap: onShowHeaders,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove\nFlake',
                  colors: colors,
                  onTap: onDelete,
                  destructive: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick info strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.outlineVariant
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: colors.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flake.statusMessage,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: flake.isRunning
                          ? const Color(0xFF81C784)
                          : const Color(0xFFEF5350),
                    ),
                  ),
                ),
                Text(
                  '↻ ${flake.checkIntervalSec}s',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual tool tile in the toolbox grid
class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final VoidCallback onTap;
  final bool destructive;

  const _ToolTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFEF5350)
        : colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: destructive
                  ? color.withValues(alpha: 0.2)
                  : colors.outlineVariant
                      .withValues(alpha: 0.2),
            ),
            color: color.withValues(alpha: 0.06),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: destructive
                      ? color
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ LOG ENTRY MODEL ═════════════════════════════════════

class _LogEntry {
  final String level;
  final String message;
  final String time;

  const _LogEntry(this.level, this.message, this.time);
}

