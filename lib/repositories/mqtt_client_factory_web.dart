import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createPlatformMqttClient({
  required String server,
  required String clientId,
  required int port,
  required int websocketPort,
  String? websocketServer,
}) {
  final _ = port;
  final wsServer = websocketServer ?? 'ws://$server';
  return MqttBrowserClient.withPort(wsServer, clientId, websocketPort);
}
