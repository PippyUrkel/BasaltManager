import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

enum SshConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SshConfig {
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKeyPem;
  final String? passphrase;

  const SshConfig({
    this.host = '127.0.0.1',
    this.port = 22,
    this.username = 'andre',
    this.password,
    this.privateKeyPem,
    this.passphrase,
  });

  SshConfig copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKeyPem,
    String? passphrase,
  }) {
    return SshConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPem: privateKeyPem ?? this.privateKeyPem,
      passphrase: passphrase ?? this.passphrase,
    );
  }

  String get summary => '$username@$host:$port';
}

class SshTerminalSession extends ChangeNotifier {
  SshConfig _config;
  SshConnectionState _state = SshConnectionState.disconnected;
  String? _errorMessage;

  SSHClient? _client;
  SSHSession? _shellSession;
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  final Terminal terminal;
  bool _isDisposed = false;

  SshTerminalSession({
    SshConfig? config,
    Terminal? terminal,
  })  : _config = config ?? const SshConfig(),
        terminal = terminal ?? Terminal(maxLines: 2000) {
    _setupTerminalHandlers();
    _printWelcome();
  }

  SshConfig get config => _config;
  SshConnectionState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _state == SshConnectionState.connected;
  bool get isConnecting => _state == SshConnectionState.connecting;

  void _printWelcome() {
    terminal.write('\x1B[1;34m╔══════════════════════════════════════════════════════════════╗\x1B[0m\r\n');
    terminal.write('\x1B[1;34m║\x1B[0m \x1B[1;32mBasalt Server Management — Terminal (dartssh2)\x1B[0m                \x1B[1;34m║\x1B[0m\r\n');
    terminal.write('\x1B[1;34m╚══════════════════════════════════════════════════════════════╝\x1B[0m\r\n');
    terminal.write('\x1B[90mTarget: ${_config.summary}\x1B[0m\r\n');
    terminal.write('\x1B[33mTap "Connect" or configure credentials to start a live SSH session.\x1B[0m\r\n\r\n');
  }

  void updateConfig(SshConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  void _setupTerminalHandlers() {
    terminal.onOutput = (String data) {
      if (_shellSession != null && _state == SshConnectionState.connected) {
        try {
          _shellSession!.stdin.add(Uint8List.fromList(utf8.encode(data)));
        } catch (e) {
          debugPrint('Error sending input to SSH: $e');
        }
      }
    };

    terminal.onResize = (int width, int height, int pixelWidth, int pixelHeight) {
      if (_shellSession != null && _state == SshConnectionState.connected) {
        try {
          _shellSession!.resizeTerminal(width, height, pixelWidth, pixelHeight);
        } catch (e) {
          debugPrint('Error resizing SSH terminal: $e');
        }
      }
    };
  }

  Future<void> connect() async {
    if (_state == SshConnectionState.connecting) return;

    await disconnect();

    _state = SshConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    terminal.write('\r\n\x1B[36mConnecting to ${_config.username}@${_config.host}:${_config.port} via dartssh2...\x1B[0m\r\n');

    try {
      final socket = await SSHSocket.connect(
        _config.host,
        _config.port,
        timeout: const Duration(seconds: 8),
      );

      List<SSHKeyPair>? identities;
      if (_config.privateKeyPem != null && _config.privateKeyPem!.trim().isNotEmpty) {
        try {
          identities = SSHKeyPair.fromPem(
            _config.privateKeyPem!,
            _config.passphrase,
          );
        } catch (e) {
          terminal.write('\x1B[31mFailed to parse private key: $e\x1B[0m\r\n');
        }
      }

      final client = SSHClient(
        socket,
        username: _config.username,
        identities: identities,
        onPasswordRequest: () {
          return _config.password ?? '';
        },
      );

      _client = client;
      await client.authenticated;

      if (_isDisposed) {
        client.close();
        return;
      }

      final shell = await client.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
          height: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
        ),
      );

      _shellSession = shell;
      _state = SshConnectionState.connected;
      notifyListeners();

      terminal.write('\x1B[1;32m✔ Authenticated & SSH shell session established.\x1B[0m\r\n\r\n');

      _stdoutSub = shell.stdout.listen(
        (data) {
          terminal.write(utf8.decode(data, allowMalformed: true));
        },
        onError: (err) {
          terminal.write('\r\n\x1B[31mStdout error: $err\x1B[0m\r\n');
        },
        onDone: () {
          _onSessionClosed();
        },
      );

      _stderrSub = shell.stderr.listen(
        (data) {
          terminal.write(utf8.decode(data, allowMalformed: true));
        },
        onError: (err) {
          terminal.write('\r\n\x1B[31mStderr error: $err\x1B[0m\r\n');
        },
      );
    } catch (e) {
      _state = SshConnectionState.error;
      _errorMessage = e.toString();
      terminal.write('\r\n\x1B[1;31m✖ Connection failed: $e\x1B[0m\r\n');
      terminal.write('\x1B[90m  • Host: ${_config.host}:${_config.port}\x1B[0m\r\n');
      terminal.write('\x1B[90m  • User: ${_config.username}\x1B[0m\r\n');
      terminal.write('\x1B[33m  • Check if SSH service is active on target and credentials are valid.\x1B[0m\r\n\r\n');
      notifyListeners();
    }
  }

  void _onSessionClosed() {
    if (_state == SshConnectionState.connected) {
      terminal.write('\r\n\x1B[33m[SSH session closed by remote host]\x1B[0m\r\n');
      _state = SshConnectionState.disconnected;
      notifyListeners();
    }
  }

  void sendCommand(String command) {
    final cmd = command.trim();
    if (cmd.isEmpty) return;

    if (_shellSession != null && _state == SshConnectionState.connected) {
      _shellSession!.stdin.add(Uint8List.fromList(utf8.encode('$cmd\n')));
    } else {
      terminal.write('\x1B[31m[Cannot send command: not connected to SSH host]\x1B[0m\r\n');
    }
  }

  void sendCtrlC() {
    sendSpecialKey('\x03');
  }

  void sendTab() {
    sendSpecialKey('\t');
  }

  void sendEsc() {
    sendSpecialKey('\x1B');
  }

  void sendArrowUp() {
    sendSpecialKey('\x1B[A');
  }

  void sendArrowDown() {
    sendSpecialKey('\x1B[B');
  }

  void sendCtrlD() {
    sendSpecialKey('\x04');
  }

  void sendCtrlL() {
    sendSpecialKey('\x0C');
  }

  void sendSpecialKey(String sequence) {
    if (_shellSession != null && _state == SshConnectionState.connected) {
      _shellSession!.stdin.add(Uint8List.fromList(utf8.encode(sequence)));
    }
  }

  void clearTerminal() {
    terminal.buffer.clear();
    terminal.eraseDisplay();
    terminal.setCursor(0, 0);
  }

  Future<void> disconnect() async {
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    await _stderrSub?.cancel();
    _stderrSub = null;

    try {
      _shellSession?.close();
    } catch (_) {}
    _shellSession = null;

    try {
      _client?.close();
    } catch (_) {}
    _client = null;

    if (_state != SshConnectionState.disconnected) {
      _state = SshConnectionState.disconnected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    super.dispose();
  }
}
