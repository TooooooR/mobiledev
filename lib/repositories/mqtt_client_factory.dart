import 'package:flutter_app/repositories/mqtt_client_factory_io.dart'
  if (dart.library.js_interop)
    'package:flutter_app/repositories/mqtt_client_factory_web.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient({
  required String server,
  required String clientId,
  required int port,
  required int websocketPort,
  String? websocketServer,
}) {
  return createPlatformMqttClient(
    server: server,
    clientId: clientId,
    port: port,
    websocketServer: websocketServer,
    websocketPort: websocketPort,
  );
}
