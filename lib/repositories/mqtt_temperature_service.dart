import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/repositories/mqtt_client_factory.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttTemperatureService {
  MqttTemperatureService({
    required this.server,
    required this.clientId,
    required this.topic,
    this.port = 1883,
    this.websocketServer,
    this.websocketPort = 9001,
  }) : _client = _buildClient(
         server: server,
         clientId: clientId,
         port: port,
         websocketServer: websocketServer,
         websocketPort: websocketPort,
       ) {
    _client.port = kIsWeb ? websocketPort : port;
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _handleDisconnected;
    _client.onConnected = _handleConnected;
  }

  final String server;
  final String clientId;
  final String topic;
  final int port;
  final String? websocketServer;
  final int websocketPort;
  final MqttClient _client;

  final StreamController<double?> _temperatureController =
      StreamController<double?>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<double?> get temperatureStream => _temperatureController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  bool get isConnected => _isConnected;
  String get transportLabel => kIsWeb ? 'WebSocket' : 'TCP';

  static MqttClient _buildClient({
    required String server,
    required String clientId,
    required int port,
    required int websocketPort,
    required String? websocketServer,
  }) {
    return createMqttClient(
      server: server,
      clientId: clientId,
      port: port,
      websocketPort: websocketPort,
      websocketServer: websocketServer,
    );
  }

  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    final client = _client;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      _setConnectionState(false);
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _setConnectionState(true);
      client.subscribe(topic, MqttQos.atMostOnce);
      _updatesSub?.cancel();
      _updatesSub = client.updates?.listen(_onMessages, onError: (_) {});
    } else {
      client.disconnect();
      _setConnectionState(false);
    }
  }

  void disconnect() {
    _client.disconnect();
    _setConnectionState(false);
  }

  void dispose() {
    disconnect();
    _updatesSub?.cancel();
    _temperatureController.close();
    _connectionController.close();
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    if (messages.isEmpty) {
      return;
    }

    final message = messages.first.payload;
    if (message is! MqttPublishMessage) {
      return;
    }

    final payload = MqttPublishPayload.bytesToStringAsString(
      message.payload.message,
    );
    final temperature = _parseTemperature(payload);
    _temperatureController.add(temperature);
  }

  double? _parseTemperature(String payload) {
    final plainNumber = double.tryParse(payload.trim());
    if (plainNumber != null) {
      return plainNumber;
    }

    try {
      final parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) {
        final dynamic value =
            parsed['temperature'] ?? parsed['temp'] ?? parsed['value'];
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          return double.tryParse(value.trim());
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  void _handleDisconnected() {
    _setConnectionState(false);
  }

  void _handleConnected() {
    _setConnectionState(true);
  }

  void _setConnectionState(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);
  }
}
