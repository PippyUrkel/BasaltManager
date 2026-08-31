import 'package:flutter/material.dart';
import '../../services/ssh_service.dart';

class SshConfigDialog extends StatefulWidget {
  final SshConfig initialConfig;
  final Function(SshConfig config, bool shouldConnect) onSave;

  const SshConfigDialog({
    super.key,
    required this.initialConfig,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required SshConfig initialConfig,
    required Function(SshConfig config, bool shouldConnect) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SshConfigDialog(
        initialConfig: initialConfig,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SshConfigDialog> createState() => _SshConfigDialogState();
}

class _SshConfigDialogState extends State<SshConfigDialog> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _privateKeyCtrl;
  late final TextEditingController _passphraseCtrl;

  int _authMethodIndex = 0; // 0 = Password, 1 = Private Key
  bool _obscurePassword = true;
  bool _obscurePassphrase = true;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: widget.initialConfig.host);
    _portCtrl = TextEditingController(text: widget.initialConfig.port.toString());
    _userCtrl = TextEditingController(text: widget.initialConfig.username);
    _passwordCtrl = TextEditingController(text: widget.initialConfig.password ?? '');
    _privateKeyCtrl = TextEditingController(text: widget.initialConfig.privateKeyPem ?? '');
    _passphraseCtrl = TextEditingController(text: widget.initialConfig.passphrase ?? '');

    if (widget.initialConfig.privateKeyPem != null &&
        widget.initialConfig.privateKeyPem!.trim().isNotEmpty) {
      _authMethodIndex = 1;
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    _privateKeyCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  SshConfig _buildConfig() {
    final port = int.tryParse(_portCtrl.text.trim()) ?? 22;
    return SshConfig(
      host: _hostCtrl.text.trim().isEmpty ? '127.0.0.1' : _hostCtrl.text.trim(),
      port: port > 0 && port <= 65535 ? port : 22,
      username: _userCtrl.text.trim().isEmpty ? 'andre' : _userCtrl.text.trim(),
      password: _authMethodIndex == 0 ? _passwordCtrl.text : null,
      privateKeyPem: _authMethodIndex == 1 && _privateKeyCtrl.text.trim().isNotEmpty
          ? _privateKeyCtrl.text.trim()
          : null,
      passphrase: _authMethodIndex == 1 && _passphraseCtrl.text.trim().isNotEmpty
          ? _passphraseCtrl.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings_ethernet_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SSH Connection Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Configure dartssh2 client credentials',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Host & Port Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _hostCtrl,
                    decoration: InputDecoration(
                      labelText: 'Host / IP Address',
                      hintText: '127.0.0.1 or server.domain',
                      prefixIcon: const Icon(Icons.computer_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      hintText: '22',
                      prefixIcon: const Icon(Icons.lan_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Username
            TextField(
              controller: _userCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'andre, root, ubuntu...',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Auth Method Selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.password_rounded, size: 16),
                  label: Text('Password'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.key_rounded, size: 16),
                  label: Text('Private Key (PEM)'),
                ),
              ],
              selected: {_authMethodIndex},
              onSelectionChanged: (set) {
                setState(() {
                  _authMethodIndex = set.first;
                });
              },
            ),

            const SizedBox(height: 14),

            if (_authMethodIndex == 0) ...[
              // Password input
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'SSH Password',
                  hintText: 'Enter user password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ] else ...[
              // Private Key input
              TextField(
                controller: _privateKeyCtrl,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  labelText: 'Private Key (OpenSSH / PEM)',
                  hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passphraseCtrl,
                obscureText: _obscurePassphrase,
                decoration: InputDecoration(
                  labelText: 'Key Passphrase (Optional)',
                  hintText: 'Leave empty if key is unencrypted',
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassphrase ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassphrase = !_obscurePassphrase;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      widget.onSave(_buildConfig(), false);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Only'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Save & Connect'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      widget.onSave(_buildConfig(), true);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
