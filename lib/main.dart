import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OutlineVpnApp());
}

class OutlineVpnApp extends StatelessWidget {
  const OutlineVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outline VPN Connector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const OutlineHomePage(),
    );
  }
}

class OutlineHomePage extends StatefulWidget {
  const OutlineHomePage({super.key});

  @override
  State<OutlineHomePage> createState() => _OutlineHomePageState();
}

class _OutlineHomePageState extends State<OutlineHomePage> {
  late final OutlineVpnController _controller;
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = OutlineVpnController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Outline VPN Connector'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OutlineKeyInputCard(
                    controller: _controller,
                    keyController: _keyController,
                  ),
                  const SizedBox(height: 16),
                  _ConnectionStatusTile(controller: _controller),
                  const SizedBox(height: 16),
                  if (_controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (_controller.config != null)
                    _ServerDetailsCard(config: _controller.config!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OutlineKeyInputCard extends StatelessWidget {
  const _OutlineKeyInputCard({
    required this.controller,
    required this.keyController,
  });

  final OutlineVpnController controller;
  final TextEditingController keyController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Outline access key',
                hintText: 'Nhập hoặc dán đường dẫn ssconf://...',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.loadKey(keyController.text),
                    icon: controller.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Tải cấu hình'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.canConnect ? controller.connect : null,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Kết nối'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.canDisconnect ? controller.disconnect : null,
              icon: const Icon(Icons.link_off),
              label: const Text('Ngắt kết nối'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatusTile extends StatelessWidget {
  const _ConnectionStatusTile({required this.controller});

  final OutlineVpnController controller;

  Color _statusColor() {
    switch (controller.vpnStateLabel) {
      case 'connected':
        return Colors.green;
      case 'connecting':
      case 'preparing':
        return Colors.orange;
      case 'disconnecting':
        return Colors.blueGrey;
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.shield, color: _statusColor()),
        title: const Text('Trạng thái VPN'),
        subtitle: Text(controller.vpnStateLabel),
        trailing: controller.lastLatency == null
            ? null
            : Text('${controller.lastLatency!.inMilliseconds} ms'),
      ),
    );
  }
}

class _ServerDetailsCard extends StatelessWidget {
  const _ServerDetailsCard({required this.config});

  final OutlineServerConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Máy chủ', value: config.serverHost),
            _InfoRow(label: 'Cổng', value: config.serverPort.toString()),
            _InfoRow(label: 'Mã hóa', value: config.method),
            if (config.accessKey != null)
              SelectableText(
                'Access key: ${config.accessKey}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (config.certSha256 != null)
              _InfoRow(label: 'Chứng chỉ', value: config.certSha256!),
            const Divider(height: 24),
            SelectableText(
              config.accessUrl,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.blueGrey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class OutlineVpnController extends ChangeNotifier {
  OutlineVpnController({http.Client? client})
      : _httpClient = client ?? http.Client() {
    _parser = OutlineKeyParser(_httpClient);
    _subscription = FlutterVpn.onStateChanged.listen(_handleStateChange);
    FlutterVpn.currentState.then(_handleStateChange);
  }

  late final OutlineKeyParser _parser;
  final http.Client _httpClient;
  OutlineServerConfig? _config;
  String? _errorMessage;
  bool _isLoading = false;
  dynamic _vpnState = 'disconnected';
  StreamSubscription<dynamic>? _subscription;
  Duration? _lastLatency;

  OutlineServerConfig? get config => _config;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get vpnStateLabel => _vpnState?.toString().split('.').last ?? 'unknown';
  bool get canConnect =>
      _config != null &&
      !_isLoading &&
      !_vpnStateLabelIn(['connecting', 'preparing', 'connected']);
  bool get canDisconnect => _vpnStateLabelIn([
        'connected',
        'connecting',
        'preparing',
        'disconnecting',
      ]);

  Duration? get lastLatency => _lastLatency;

  Future<void> loadKey(String rawKey) async {
    _setLoading(true);
    _setError(null);
    try {
      final stopwatch = Stopwatch()..start();
      final config = await _parser.parse(rawKey);
      stopwatch.stop();
      _lastLatency = stopwatch.elapsed;
      _config = config;
    } on FormatException catch (error) {
      _setError(error.message);
      _config = null;
    } on http.ClientException catch (error) {
      _setError('Không thể tải cấu hình: ${error.message}');
      _config = null;
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
      _config = null;
    } catch (error) {
      _setError('Đã xảy ra lỗi: $error');
      _config = null;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_config == null) {
      _setError('Chưa có cấu hình máy chủ.');
      return;
    }
    _setError(null);
    try {
      await FlutterVpn.prepare();
      final String accessUrl = _config!.accessUrl;
      if (accessUrl.startsWith('ss://')) {
        throw PlatformException(
          code: 'UNSUPPORTED',
          message:
              'Kết nối Outline/Shadowsocks chưa được hỗ trợ bởi flutter_vpn hiện tại. Vui lòng dùng plugin tương thích Outline hoặc cung cấp cấu hình IKEv2/IPSec.',
        );
      }
      // If later supporting IKEv2/IPSec, call corresponding FlutterVpn.connect* here.
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } catch (error) {
      _setError('Không thể kết nối: $error');
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await FlutterVpn.disconnect();
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } catch (error) {
      _setError('Không thể ngắt kết nối: $error');
    }
    notifyListeners();
  }

  void _handleStateChange(dynamic state) {
    _vpnState = state;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool _vpnStateLabelIn(List<String> states) {
    final label = vpnStateLabel;
    return states.contains(label);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _httpClient.close();
    super.dispose();
  }
}

class OutlineServerConfig {
  OutlineServerConfig({
    required this.serverHost,
    required this.serverPort,
    required this.method,
    required this.password,
    required this.name,
    required this.accessUrl,
    this.accessKey,
    this.certSha256,
    this.rawJson,
  });

  final String serverHost;
  final int serverPort;
  final String method;
  final String password;
  final String name;
  final String accessUrl;
  final String? accessKey;
  final String? certSha256;
  final Map<String, dynamic>? rawJson;

  String get displayName => name.isEmpty ? '$serverHost:$serverPort' : name;

  Map<String, dynamic> toJson() => {
        'serverHost': serverHost,
        'serverPort': serverPort,
        'method': method,
        'password': password,
        'name': name,
        'accessUrl': accessUrl,
        if (accessKey != null) 'accessKey': accessKey,
        if (certSha256 != null) 'certSha256': certSha256,
      };
}

class OutlineKeyParser {
  OutlineKeyParser(this._client);

  final http.Client _client;

  Future<OutlineServerConfig> parse(String rawKey) async {
    if (rawKey.trim().isEmpty) {
      throw const FormatException('Vui lòng nhập access key hợp lệ.');
    }

    final uri = Uri.tryParse(rawKey.trim());
    if (uri == null || uri.scheme != 'ssconf') {
      throw const FormatException('Access key phải bắt đầu bằng ssconf://');
    }

    final httpsUri = uri.replace(scheme: 'https');
    final response = await _client.get(httpsUri);
    if (response.statusCode != 200) {
      throw FormatException(
        'Máy chủ trả về mã lỗi ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Tệp cấu hình không hợp lệ.');
    }

    return _parseServerConfig(decoded, uri.fragment.isEmpty ? null : uri.fragment);
  }

  OutlineServerConfig _parseServerConfig(
    Map<String, dynamic> json,
    String? fragment,
  ) {
    String? serverHost = json['host'] as String? ?? json['server'] as String?;
    final int? port =
        (json['server_port'] as num?)?.toInt() ?? (json['port'] as num?)?.toInt();
    final String? method = json['method'] as String?;
    final String? password = json['password'] as String? ?? json['secret'] as String?;
    final String? name = fragment ?? json['name'] as String?;
    final String? accessKey = json['access_key'] as String? ?? json['accessKey'] as String?;
    final String? accessUrl =
        json['accessUrl'] as String? ?? json['access_url'] as String? ?? accessKey;
    final String? certSha = json['certSha256'] as String? ?? json['cert_sha256'] as String?;

    if (serverHost == null || port == null || method == null || password == null) {
      throw const FormatException('Thiếu thông tin máy chủ trong tệp cấu hình.');
    }

    final computedAccessUrl = accessUrl ?? _buildAccessUrl(
      serverHost: serverHost,
      port: port,
      method: method,
      password: password,
    );

    return OutlineServerConfig(
      serverHost: serverHost,
      serverPort: port,
      method: method,
      password: password,
      name: name ?? '',
      accessUrl: computedAccessUrl,
      accessKey: accessKey,
      certSha256: certSha,
      rawJson: json,
    );
  }

  String _buildAccessUrl({
    required String serverHost,
    required int port,
    required String method,
    required String password,
  }) {
    final credentials = base64Url.encode(utf8.encode('$method:$password')).replaceAll('=', '');
    return 'ss://$credentials@$serverHost:$port/?outline=1';
  }

}
