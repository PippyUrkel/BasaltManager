import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../../services/ssh_service.dart';
import '../../core/theme/terminal_theme.dart';
import '../widgets/ssh_config_dialog.dart';

class SshTerminalScreen extends StatefulWidget {
  final SshTerminalSession session;
  final String title;

  const SshTerminalScreen({
    super.key,
    required this.session,
    this.title = 'Host Terminal (SSH)',
  });

  @override
  State<SshTerminalScreen> createState() => _SshTerminalScreenState();
}

class _SshTerminalScreenState extends State<SshTerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocusNode = FocusNode();

  final List<String> _quickCommands = [
    'uptime',
    'df -h',
    'free -m',
    'uname -a',
    'docker ps',
    'systemctl status basalt',
    'top -b -n 1',
    'ss -tulpn',
  ];

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionStateChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionStateChanged);
    _commandController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  void _onSessionStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _submitCommand(String text) {
    final cmd = text.trim();
    if (cmd.isEmpty) return;
    _commandController.clear();
    widget.session.sendCommand(cmd);
  }

  void _openConfig() {
    SshConfigDialog.show(
      context,
      initialConfig: widget.session.config,
      onSave: (newConfig, shouldConnect) {
        widget.session.updateConfig(newConfig);
        if (shouldConnect) {
          widget.session.connect();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final session = widget.session;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              session.config.summary,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: colors.outline,
              ),
            ),
          ],
        ),
        actions: [
          // Connection status badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildStatusBadge(session),
          ),
          const SizedBox(width: 4),

          // Connect / Disconnect button
          if (session.isConnected)
            IconButton(
              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
              tooltip: 'Disconnect SSH',
              onPressed: session.disconnect,
            )
          else if (session.isConnecting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.link_rounded, color: Color(0xFF81C784)),
              tooltip: 'Connect SSH',
              onPressed: session.connect,
            ),

          // Config Dialog Button
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'SSH Settings',
            onPressed: _openConfig,
          ),

          // Clear Terminal Button
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Clear Screen',
            onPressed: session.clearTerminal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if connection failed
            if (session.state == SshConnectionState.error)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.errorMessage ?? 'SSH connection error',
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: session.connect,
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: _openConfig,
                      child: const Text('Configure'),
                    ),
                  ],
                ),
              ),

            // Main Terminal Screen View
            Expanded(
              child: Container(
                color: const Color(0xFF0D1117),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TerminalView(
                  session.terminal,
                  focusNode: _terminalFocusNode,
                  theme: BasaltTerminalTheme.darkTheme,
                  textStyle: const TerminalStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  autofocus: true,
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFF30363D)),

            // Shortcut keys bar (Ctrl+C, Tab, Esc, Up, Down, etc.)
            Container(
              color: const Color(0xFF161B22),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShortcutButton('Ctrl+C', () => session.sendCtrlC(), colors, isDanger: true),
                    _buildShortcutButton('Tab', () => session.sendTab(), colors),
                    _buildShortcutButton('ESC', () => session.sendEsc(), colors),
                    _buildShortcutButton('▲ Up', () => session.sendArrowUp(), colors),
                    _buildShortcutButton('▼ Down', () => session.sendArrowDown(), colors),
                    _buildShortcutButton('Ctrl+D', () => session.sendCtrlD(), colors),
                    _buildShortcutButton('Ctrl+L', () => session.sendCtrlL(), colors),
                    const SizedBox(width: 8),
                    Container(height: 16, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(width: 8),
                    ..._quickCommands.map((cmd) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFF21262D),
                          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.2)),
                          label: Text(
                            cmd,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFF58A6FF),
                            ),
                          ),
                          onPressed: () => _submitCommand(cmd),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Command input row
            Container(
              color: const Color(0xFF161B22),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: session.isConnected
                            ? 'Send shell command (or type directly above)...'
                            : 'Connect SSH to execute commands...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: colors.outline.withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '>',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF58A6FF),
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 22, minHeight: 0),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      onSubmitted: _submitCommand,
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
                    tooltip: 'Send',
                    onPressed: () => _submitCommand(_commandController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(
    String label,
    VoidCallback onPressed,
    ColorScheme colors, {
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDanger
                ? Colors.red.withValues(alpha: 0.15)
                : const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDanger
                  ? Colors.red.withValues(alpha: 0.3)
                  : const Color(0xFF30363D),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isDanger ? Colors.redAccent : const Color(0xFFE6EDF3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SshTerminalSession session) {
    Color bg;
    Color fg;
    String text;

    switch (session.state) {
      case SshConnectionState.connected:
        bg = const Color(0xFF1B3D20);
        fg = const Color(0xFF4CAF50);
        text = 'LIVE SSH';
        break;
      case SshConnectionState.connecting:
        bg = const Color(0xFF3E3113);
        fg = Colors.amber;
        text = 'CONNECTING';
        break;
      case SshConnectionState.error:
        bg = const Color(0xFF3B1A1A);
        fg = Colors.redAccent;
        text = 'ERROR';
        break;
      case SshConnectionState.disconnected:
        bg = const Color(0xFF21262D);
        fg = Colors.grey;
        text = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fg,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
