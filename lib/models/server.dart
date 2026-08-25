import 'package:flutter/material.dart';

enum ServerStatus {
  running,
  stopped,
  restarting,
  error,
}

typedef Flake = Server;

class Server {
  final String id;
  final String name;
  final String host;
  final int port;
  final String protocol; // HTTP, HTTPS, TCP, UDP, WS
  final ServerStatus status;
  final String flakeType; // Web API, Game Server, SQL DB, Cache, etc.
  final String flakeRef;  // e.g. 'localhost:8000/health' or service identifier
  final String healthPath;
  final int checkIntervalSec;
  final int latencyMs;
  final double uptimePercentage;
  final List<double> latencyHistory;
  final String uptime;
  final double cpuUsage;
  final double memoryUsagePercent;
  final String memoryUsageString;
  final String networkSpeed;
  final IconData icon;
  final String environment;
  final String statusMessage;

  const Server({
    required this.id,
    required this.name,
    this.host = '127.0.0.1',
    required this.port,
    this.protocol = 'HTTP',
    this.status = ServerStatus.running,
    this.flakeType = 'Service',
    this.flakeRef = '',
    this.healthPath = '/health',
    this.checkIntervalSec = 15,
    this.latencyMs = 18,
    this.uptimePercentage = 99.9,
    this.latencyHistory = const [14, 18, 15, 22, 17, 19, 16],
    this.uptime = '0m',
    this.cpuUsage = 0.0,
    this.memoryUsagePercent = 0.0,
    this.memoryUsageString = '0 MB',
    this.networkSpeed = '0 KB/s',
    this.icon = Icons.dns_rounded,
    this.environment = 'Production',
    this.statusMessage = 'Active & Responding',
  });

  bool get isRunning => status == ServerStatus.running;
  bool get isOffline => status == ServerStatus.stopped;

  String get endpointUrl => '$host:$port$healthPath';
  String get address => '$host:$port';

  Server copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? protocol,
    ServerStatus? status,
    String? flakeType,
    String? flakeRef,
    String? healthPath,
    int? checkIntervalSec,
    int? latencyMs,
    double? uptimePercentage,
    List<double>? latencyHistory,
    String? uptime,
    double? cpuUsage,
    double? memoryUsagePercent,
    String? memoryUsageString,
    String? networkSpeed,
    IconData? icon,
    String? environment,
    String? statusMessage,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      status: status ?? this.status,
      flakeType: flakeType ?? this.flakeType,
      flakeRef: flakeRef ?? this.flakeRef,
      healthPath: healthPath ?? this.healthPath,
      checkIntervalSec: checkIntervalSec ?? this.checkIntervalSec,
      latencyMs: latencyMs ?? this.latencyMs,
      uptimePercentage: uptimePercentage ?? this.uptimePercentage,
      latencyHistory: latencyHistory ?? this.latencyHistory,
      uptime: uptime ?? this.uptime,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsagePercent: memoryUsagePercent ?? this.memoryUsagePercent,
      memoryUsageString: memoryUsageString ?? this.memoryUsageString,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      icon: icon ?? this.icon,
      environment: environment ?? this.environment,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
