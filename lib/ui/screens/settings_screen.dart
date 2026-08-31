import 'package:flutter/material.dart';
import '../../services/ssh_service.dart';
import '../widgets/ssh_config_dialog.dart';
import 'ssh_terminal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SshConfig _defaultConfig = const SshConfig(
    host: '127.0.0.1',
    port: 22,
    username: 'andre',
  );

  bool _autoConnectTerminal = false;
  double _terminalFontSize = 12.0;

  void _configureSsh() {
    SshConfigDialog.show(
      context,
      initialConfig: _defaultConfig,
      onSave: (config, shouldConnect) {
        setState(() {
          _defaultConfig = config;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SSH default target updated to ${config.summary}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (shouldConnect) {
          _launchTerminal();
        }
      },
    );
  }

  void _launchTerminal() {
    final session = SshTerminalSession(config: _defaultConfig);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SshTerminalScreen(
          session: session,
          title: 'SSH Terminal — ${_defaultConfig.host}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ─── SSH Configuration Section ───
          _buildSectionHeader('SSH CLIENT ENGINE (DARTSSH2)', colors),
          Card(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.terminal_rounded, color: colors.primary),
                  ),
                  title: const Text('Default SSH Target'),
                  subtitle: Text(
                    _defaultConfig.summary,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _configureSsh,
                    child: const Text('Configure'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded),
                  title: const Text('Launch SSH Terminal'),
                  subtitle: const Text('Open dedicated full-screen interactive shell'),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Launch'),
                    onPressed: _launchTerminal,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.autorenew_rounded),
                  title: const Text('Auto-connect on Dashboard'),
                  subtitle: const Text('Initiate SSH connection automatically when viewing dashboard'),
                  value: _autoConnectTerminal,
                  onChanged: (val) {
                    setState(() {
                      _autoConnectTerminal = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Terminal Appearance ───
          _buildSectionHeader('TERMINAL PREFERENCES', colors),
          Card(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.format_size_rounded),
                  title: const Text('Terminal Font Size'),
                  subtitle: Text('${_terminalFontSize.toInt()} pt monospace'),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      value: _terminalFontSize,
                      min: 10,
                      max: 18,
                      divisions: 8,
                      label: '${_terminalFontSize.toInt()} pt',
                      onChanged: (val) {
                        setState(() {
                          _terminalFontSize = val;
                        });
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Terminal Color Palette'),
                  subtitle: const Text('Basalt Dark (VT100 256-color compatible)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: const Text(
                      'ANSI 256',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF58A6FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About Section ───
          _buildSectionHeader('SYSTEM & LIBRARIES', colors),
          Card(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('SSH Client Engine'),
                  subtitle: const Text('dartssh2 v4.0.0 (Pure Dart SSHv2 protocol)'),
                  trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF81C784)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.memory_rounded),
                  title: const Text('Terminal Emulator'),
                  subtitle: const Text('xterm v4.0.0 (VT100/ANSI canvas renderer)'),
                  trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF81C784)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.layers_outlined),
                  title: const Text('Basalt Server Management'),
                  subtitle: const Text('Version 1.0.0+1 • Production build'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: colors.outline,
        ),
      ),
    );
  }
}