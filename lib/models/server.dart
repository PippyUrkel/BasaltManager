import 'package:flutter/material.dart';

enum ServerStatus {
  running,
  stopped,
  restarting,
  error,
}

class Server {
  final String id;
  final String name;
  final int port;
  final ServerStatus status;
  final String flakeType;
  final String flakeRef;
  final String uptime;
  final double cpuUsage;
  final double memoryUsagePercent;
  final String memoryUsageString;
  final String networkSpeed;
  final IconData icon;
  final String environment;

  const Server({
    required this.id,
    required this.name,
    required this.port,
    this.status = ServerStatus.running,
    this.flakeType = 'Service',
    this.flakeRef = 'flake.nix',
    this.uptime = '0m',
    this.cpuUsage = 0.0,
    this.memoryUsagePercent = 0.0,
    this.memoryUsageString = '0 MB',
    this.networkSpeed = '0 KB/s',
    this.icon = Icons.dns_rounded,
    this.environment = 'Production',
  });

  bool get isRunning => status == ServerStatus.running;

  Server copyWith({
    String? id,
    String? name,
    int? port,
    ServerStatus? status,
    String? flakeType,
    String? flakeRef,
    String? uptime,
    double? cpuUsage,
    double? memoryUsagePercent,
    String? memoryUsageString,
    String? networkSpeed,
    IconData? icon,
    String? environment,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      port: port ?? this.port,
      status: status ?? this.status,
      flakeType: flakeType ?? this.flakeType,
      flakeRef: flakeRef ?? this.flakeRef,
      uptime: uptime ?? this.uptime,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsagePercent: memoryUsagePercent ?? this.memoryUsagePercent,
      memoryUsageString: memoryUsageString ?? this.memoryUsageString,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      icon: icon ?? this.icon,
      environment: environment ?? this.environment,
    );
  }
}