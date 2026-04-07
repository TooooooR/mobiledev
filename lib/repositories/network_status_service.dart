import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkStatusService {
  final InternetConnection _connection = InternetConnection();

  Future<bool> isOnline() async {
    return _connection.hasInternetAccess;
  }

  Stream<bool> get onStatusChanged {
    return _connection.onStatusChange
        .map((status) => status == InternetStatus.connected)
        .distinct();
  }
}
