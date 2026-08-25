class MonitoredPort {
  final int port;
  final String serviceName;
  final String protocol;
  final bool isOpen;
  final String? processName;
  final int? pid;
  final String host;
  final String category;

  const MonitoredPort({
    required this.port,
    required this.serviceName,
    this.protocol = 'TCP',
    this.isOpen = true,
    this.processName,
    this.pid,
    this.host = '127.0.0.1',
    this.category = 'Service',
  });
}