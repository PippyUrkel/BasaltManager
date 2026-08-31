import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../../services/ssh_service.dart';
import '../../core/theme/terminal_theme.dart';
import '../screens/ssh_terminal_screen.dart';
import 'ssh_config_dialog.dart';

class SshTerminalCard extends StatefulWidget {
  final String host;
  final String username;
  final int port;
  final String? password;
  final String? privateKeyPem;
  final bool autoConnect;

  const SshTerminalCard({
    super.key,
    this.host = '127.0.0.1',
    this.username = 'andre',
    this.port = 22,
    this.password,
    this.privateKeyPem,
    this.autoConnect = false,
  });

  @override
  State<SshTerminalCard> createState() => _SshTerminalCardState();
}

class _SshTerminalCardState extends State<SshTerminalCard> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocusNode = FocusNode();
  late SshTerminalSession _session;

  final List<String> _quickCommands = [
    'uptime',
    'df -h',
    'free -m',
    'uname -a',
    'docker ps',
    'systemctl status basalt',
  ];

  @override
  void initState() {
    super.initState();
    _session = SshTerminalSession(
      config: SshConfig(
        host: widget.host,
        port: widget.port,
        username: widget.username,
        password: widget.password,
        privateKeyPem: widget.privateKeyPem,
      ),
    );
    _session.addListener(_onSessionUpdate);

    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _session.connect();
      });
    }
  }

  @override
  void didUpdateWidget(SshTerminalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host != widget.host ||
        oldWidget.port != widget.port ||
        oldWidget.username != widget.username) {
      _session.updateConfig(
        _session.config.copyWith(
          host: widget.host,
          port: widget.port,
          username: widget.username,
        ),
      );
    }
  }

  void _onSessionUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionUpdate);
    _session.dispose();
    _commandController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  void _runCommand(String command) {
    final cmd = command.trim();
    if (cmd.isEmpty) return;
    _commandController.clear();
    _session.sendCommand(cmd);
  }

  void _openConfigDialog() {
    SshConfigDialog.show(
      context,
      initialConfig: _session.config,
      onSave: (newConfig, shouldConnect) {
        _session.updateConfig(newConfig);
        if (shouldConnect) {
          _session.connect();
        }
      },
    );
  }

  void _openFullscreenTerminal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SshTerminalScreen(
          session: _session,
          title: 'SSH Terminal — ${_session.config.host}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _session.isConnected
              ? colors.primary.withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Bar ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Host Terminal',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '(dartssh2)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF58A6FF),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _session.config.summary,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connected status pill
                _buildStatusPill(),
                const SizedBox(width: 4),

                // Connect / Disconnect button
                if (_session.isConnected)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: 'Disconnect SSH',
                    icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                    onPressed: _session.disconnect,
                  )
                else if (_session.isConnecting)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: 'Connect SSH',
                    icon: const Icon(Icons.link_rounded, color: Color(0xFF81C784)),
                    onPressed: _session.connect,
                  ),

                // Settings dialog button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip: 'SSH Connection Settings',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openConfigDialog,
                ),

                // Fullscreen button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip: 'Open Fullscreen Terminal',
                  icon: const Icon(Icons.fullscreen_rounded),
                  onPressed: _openFullscreenTerminal,
                ),

                // Clear button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip: 'Clear Output',
                  icon: const Icon(Icons.cleaning_services_rounded),
                  onPressed: _session.clearTerminal,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── Interactive Terminal Screen Area ───
          Container(
            height: 185,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF0D1117),
            child: Stack(
              children: [
                TerminalView(
                  _session.terminal,
                  focusNode: _terminalFocusNode,
                  theme: BasaltTerminalTheme.darkTheme,
                  textStyle: const TerminalStyle(
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                  ),
                ),

                // Disconnected overlay helper if idle
                if (_session.state == SshConnectionState.disconnected)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.85),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 14),
                      label: const Text('Connect Live SSH', style: TextStyle(fontSize: 11)),
                      onPressed: _session.connect,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── Shortcut Toolbar (Ctrl+C, Tab, Esc, Quick Commands) ───
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMiniKey('Ctrl+C', () => _session.sendCtrlC(), isDanger: true),
                  _buildMiniKey('Tab', () => _session.sendTab()),
                  _buildMiniKey('ESC', () => _session.sendEsc()),
                  _buildMiniKey('▲', () => _session.sendArrowUp()),
                  _buildMiniKey('▼', () => _session.sendArrowDown()),
                  const SizedBox(width: 6),
                  Container(height: 14, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  ..._quickCommands.map((cmd) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _runCommand(cmd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF30363D),
                            ),
                          ),
                          child: Text(
                            cmd,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              color: Color(0xFF58A6FF),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ─── Command Input Field ───
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: _session.isConnected
                          ? 'Enter shell command (e.g. htop, uptime)...'
                          : 'Connect to host to send shell commands...',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: colors.outline.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '>',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF58A6FF),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 0,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF58A6FF)),
                      ),
                    ),
                    onSubmitted: _runCommand,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  tooltip: 'Execute Command',
                  onPressed: () => _runCommand(_commandController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKey(String label, VoidCallback onTap, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDanger ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isDanger ? Colors.red.withValues(alpha: 0.3) : const Color(0xFF30363D),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isDanger ? Colors.redAccent : const Color(0xFFE6EDF3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    Color bg;
    Color border;
    String text;

    switch (_session.state) {
      case SshConnectionState.connected:
        bg = const Color(0xFF1B3D20);
        border = const Color(0xFF4CAF50);
        text = 'SSH LIVE';
        break;
      case SshConnectionState.connecting:
        bg = const Color(0xFF3E3113);
        border = Colors.amber;
        text = 'CONNECTING';
        break;
      case SshConnectionState.error:
        bg = const Color(0xFF3B1A1A);
        border = Colors.redAccent;
        text = 'SSH ERROR';
        break;
      case SshConnectionState.disconnected:
        bg = const Color(0xFF21262D);
        border = const Color(0xFF484F58);
        text = 'DISCONNECTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: border,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: border,
            ),
          ),
        ],
      ),
    );
  }
}
