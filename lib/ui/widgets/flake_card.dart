import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/server.dart';

/// A card representing a monitored Flake (server/service endpoint) with
/// real-time telemetry, latency sparkline, status badge, and expandable tools.
class FlakeCard extends StatelessWidget {
  final Server flake;
  final bool isPinging;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onPing;
  final VoidCallback? onDelete;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onShowLog;
  final VoidCallback? onShowTrace;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onOpenTerminal;

  const FlakeCard({
    super.key,
    required this.flake,
    this.isPinging = false,
    this.isExpanded = false,
    this.onToggle,
    this.onPing,
    this.onDelete,
    this.onExpandToggle,
    this.onShowLog,
    this.onShowTrace,
    this.onShowHeaders,
    this.onOpenTerminal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRunning = flake.isRunning;

    // Visual accents
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
              // ─── Main Card Header ───
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                onTap: onExpandToggle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Row 1: Identity, Protocol, Address, Status
                      Row(
                        children: [
                          _FlakeAvatar(
                            icon: flake.icon,
                            isRunning: isRunning,
                            colors: colors,
                          ),
                          const SizedBox(width: 14),

                          // Name + Address
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flake.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Protocol pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerHighest
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        flake.protocol,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Address
                                    Flexible(
                                      child: Text(
                                        '${flake.host}:${flake.port}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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

                          // Status + Latency Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
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

                      // Row 2: Latency Sparkline + Metric Stats
                      Row(
                        children: [
                          // Sparkline graph
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

                      // Row 3: Quick Action Buttons
                      Row(
                        children: [
                          _FlakeActionButton(
                            icon: isPinging ? null : Icons.bolt_rounded,
                            label: isPinging ? 'Pinging...' : 'Ping',
                            isPinging: isPinging,
                            onPressed: isPinging ? null : onPing,
                            colors: colors,
                            filled: true,
                          ),
                          const SizedBox(width: 8),
                          _FlakeActionButton(
                            icon: isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            label: isRunning ? 'Pause' : 'Resume',
                            onPressed: onToggle,
                            colors: colors,
                          ),
                          const Spacer(),
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

              // ─── Expandable Toolbox Section ───
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _FlakeToolbox(
                  flake: flake,
                  colors: colors,
                  onShowLog: onShowLog ?? () {},
                  onShowTrace: onShowTrace ?? () {},
                  onShowHeaders: onShowHeaders ?? () {},
                  onOpenTerminal: onOpenTerminal ?? () {},
                  onDelete: onDelete ?? () {},
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

// ═══════════════════════ SUBCOMPONENTS ═══════════════════════════════════════

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

/// Status chip (LIVE / DOWN)
class _StatusChip extends StatelessWidget {
  final bool isRunning;
  final ColorScheme colors;

  const _StatusChip({required this.isRunning, required this.colors});

  @override
  Widget build(BuildContext context) {
    final color =
        isRunning ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

    final lineColor = isRunning
        ? colors.primary
        : colors.outline.withValues(alpha: 0.4);
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

/// Small stat pill for uptime / percentage
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: highlight
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: highlight
              ? Border.all(color: colors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: highlight ? colors.primary : colors.outline,
            ),
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

/// Action button used within the flake card
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}

/// Expandable monitoring tools section
class _FlakeToolbox extends StatelessWidget {
  final Server flake;
  final ColorScheme colors;
  final VoidCallback onShowLog;
  final VoidCallback onShowTrace;
  final VoidCallback onShowHeaders;
  final VoidCallback onOpenTerminal;
  final VoidCallback onDelete;

  const _FlakeToolbox({
    required this.flake,
    required this.colors,
    required this.onShowLog,
    required this.onShowTrace,
    required this.onShowHeaders,
    required this.onOpenTerminal,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbox header
          Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 14,
                color: colors.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'MONITORING & MANAGEMENT TOOLS',
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
                  icon: Icons.terminal_rounded,
                  label: 'SSH\nTerminal',
                  colors: colors,
                  onTap: onOpenTerminal,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ToolTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Connection\nLog',
                  colors: colors,
                  onTap: onShowLog,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ToolTile(
                  icon: Icons.route_rounded,
                  label: 'Trace\nRoute',
                  colors: colors,
                  onTap: onShowTrace,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ToolTile(
                  icon: Icons.code_rounded,
                  label: 'Response\nHeaders',
                  colors: colors,
                  onTap: onShowHeaders,
                ),
              ),
              const SizedBox(width: 6),
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

          // Status & interval strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: colors.outline,
                ),
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

/// Tool action tile in the toolbox grid
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
    final color = destructive ? const Color(0xFFEF5350) : colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: destructive
                  ? color.withValues(alpha: 0.2)
                  : colors.outlineVariant.withValues(alpha: 0.2),
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
                  color: destructive ? color : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
