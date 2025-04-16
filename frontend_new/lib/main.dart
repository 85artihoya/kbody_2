import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_new/services/auth_service.dart';
import 'package:frontend_new/providers/auth_provider.dart';
import 'package:frontend_new/routes/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Flutter 바인딩 초기화 추가
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (_) => AuthProvider(authService),
          update: (_, auth, previous) => previous ?? AuthProvider(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'K-Body',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: Routes.router,
      ),
    );
  }
}
