import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createPlatformMqttClient({
  required String server,
  required String clientId,
  required int port,
  required int websocketPort,
  String? websocketServer,
}) {
  final _ = (websocketServer, websocketPort);
  return MqttServerClient.withPort(server, clientId, port);
}
