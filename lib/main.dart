import 'package:flutter/material.dart';
import 'package:flutter_app/cubits/auth_cubit.dart';
import 'package:flutter_app/cubits/home_cubit.dart';
import 'package:flutter_app/cubits/profile_cubit.dart';
import 'package:flutter_app/pages/home_page.dart';
import 'package:flutter_app/pages/login_page.dart';
import 'package:flutter_app/pages/profile_page.dart';
import 'package:flutter_app/pages/register_page.dart';
import 'package:flutter_app/repositories/api_auth_repository.dart';
import 'package:flutter_app/repositories/i_auth_repository.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:flutter_app/repositories/mqtt_temperature_service.dart';
import 'package:flutter_app/repositories/network_status_service.dart';
import 'package:flutter_app/repositories/session_user_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasUser = prefs.containsKey('current_session_user');
  
  runApp(PCMonitor(initialRoute: hasUser ? '/home' : '/login'));
}

class PCMonitor extends StatelessWidget {
  final String initialRoute;
  const PCMonitor({required this.initialRoute, super.key});

  static const _mqttServer = '10.156.119.71';
  static const _mqttWebSocketServer = 'ws://10.156.119.71';
  static const _mqttTopic = 'esp8266/temperature';

  MqttTemperatureService _createMqttService() {
    final clientId =
        'flutter_profile_${DateTime.now().millisecondsSinceEpoch}';

    return MqttTemperatureService(
      server: _mqttServer,
      clientId: clientId,
      topic: _mqttTopic,
      websocketServer: _mqttWebSocketServer,
    );
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(
              networkStatus: context.read<NetworkStatusService>(),
              sessionUserStorage: context.read<SessionUserStorage>(),
            )..initialize(settings.arguments),
            child: const HomeScreen(),
          ),
        );
      case '/profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              localAuthRepository: context.read<LocalAuthRepository>(),
              apiAuthRepository: context.read<ApiAuthRepository>(),
              sessionUserStorage: context.read<SessionUserStorage>(),
              mqttService: context.read<MqttTemperatureService>(),
            )..initialize(),
            child: const ProfileScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalAuthRepository>(
          create: (_) => LocalAuthRepository(),
        ),
        RepositoryProvider<ApiAuthRepository>(
          create: (context) => ApiAuthRepository(
            localRepository: context.read<LocalAuthRepository>(),
          ),
        ),
        RepositoryProvider<IAuthRepository>(
          create: (context) => context.read<ApiAuthRepository>(),
        ),
        RepositoryProvider<SessionUserStorage>(
          create: (_) => SessionUserStorage(),
        ),
        RepositoryProvider<NetworkStatusService>(
          create: (_) => NetworkStatusService(),
        ),
        RepositoryProvider<MqttTemperatureService>(
          create: (_) => _createMqttService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              authRepository: context.read<IAuthRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'PCMonitor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.cyanAccent,
              brightness: Brightness.dark,
            ),
          ),
          initialRoute: initialRoute,
          onGenerateRoute: _buildRoute,
        ),
      ),
    );
  }
}
