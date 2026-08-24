import 'package:flutter/material.dart';
import '../../models/server.dart';

class ServerCard extends StatelessWidget {
  final Server? server;
  final String name;
  final int port;
  final bool running;
  final String flakeType;
  final String flakeRef;
  final String uptime;
  final double cpuUsage;
  final String memoryUsage;
  final String networkSpeed;
  final IconData icon;
  final String environment;
  final VoidCallback? onToggle;
  final VoidCallback? onRestart;
  final VoidCallback? onTerminal;
  final VoidCallback? onTap;

  ServerCard({
    super.key,
    this.server,
    String? name,
    int? port,
    bool? running,
    String? flakeType,
    String? flakeRef,
    String? uptime,
    double? cpuUsage,
    String? memoryUsage,
    String? networkSpeed,
    IconData? icon,
    String? environment,
    this.onToggle,
    this.onRestart,
    this.onTerminal,
    this.onTap,
  })  : name = name ?? server?.name ?? 'Server',
        port = port ?? server?.port ?? 8080,
        running = running ?? server?.isRunning ?? false,
        flakeType = flakeType ?? server?.flakeType ?? 'Nix Flake',
        flakeRef = flakeRef ?? server?.flakeRef ?? 'flake.nix',
        uptime = uptime ?? server?.uptime ?? (running == true ? '1h 24m' : 'Offline'),
        cpuUsage = cpuUsage ?? server?.cpuUsage ?? (running == true ? 12.5 : 0.0),
        memoryUsage = memoryUsage ?? server?.memoryUsageString ?? (running == true ? '256 MB' : '0 MB'),
        networkSpeed = networkSpeed ?? server?.networkSpeed ?? (running == true ? '120 KB/s' : '0 KB/s'),
        icon = icon ?? server?.icon ?? Icons.dns_rounded,
        environment = environment ?? server?.environment ?? 'Production';

  factory ServerCard.fromServer(
    Server server, {
    Key? key,
    VoidCallback? onToggle,
    VoidCallback? onRestart,
    VoidCallback? onTerminal,
    VoidCallback? onTap,
  }) {
    return ServerCard(
      key: key,
      server: server,
      name: server.name,
      port: server.port,
      running: server.isRunning,
      flakeType: server.flakeType,
      flakeRef: server.flakeRef,
      uptime: server.uptime,
      cpuUsage: server.cpuUsage,
      memoryUsage: server.memoryUsageString,
      networkSpeed: server.networkSpeed,
      icon: server.icon,
      environment: server.environment,
      onToggle: onToggle,
      onRestart: onRestart,
      onTerminal: onTerminal,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: running ? 3 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: running
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      color: running
          ? colors.surfaceContainerHigh
          : colors.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Identity & Status Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: running
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: running
                            ? colors.primary.withValues(alpha: 0.3)
                            : colors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: running ? colors.primary : colors.outline,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                flakeType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                flakeRef,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.outline,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  _buildStatusBadge(colors),
                ],
              ),

              const SizedBox(height: 12),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      colors: colors,
                      icon: Icons.lan_outlined,
                      label: 'PORT',
                      value: ':$port',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      colors: colors,
                      icon: Icons.timer_outlined,
                      label: 'UPTIME',
                      value: running ? uptime : 'Offline',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      colors: colors,
                      icon: Icons.memory_outlined,
                      label: 'CPU',
                      value: running ? '${cpuUsage.toStringAsFixed(0)}%' : '0%',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      colors: colors,
                      icon: Icons.storage_outlined,
                      label: 'RAM',
                      value: running ? memoryUsage : '0 MB',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Power Button
                  SizedBox(
                    height: 36,
                    child: running
                        ? FilledButton.tonalIcon(
                            onPressed: onToggle,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.redAccent.withValues(alpha: 0.15),
                              foregroundColor: const Color(0xFFEF5350),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.power_settings_new_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Stop',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: onToggle,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),

                  // Secondary Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        context: context,
                        icon: Icons.restart_alt_rounded,
                        tooltip: 'Restart Flake',
                        onPressed: running ? onRestart : null,
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        context: context,
                        icon: Icons.terminal_rounded,
                        tooltip: 'Terminal Logs',
                        onPressed: onTerminal,
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        context: context,
                        icon: Icons.more_vert_rounded,
                        tooltip: 'Server Options',
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme colors) {
    final statusColor = running
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE57373);
    final statusBgColor = running
        ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
        : const Color(0xFFB71C1C).withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: running
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.6),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            running ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 10,
                color: colors.outline,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colors.outline,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          foregroundColor: onPressed != null ? colors.onSurfaceVariant : colors.outline.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}