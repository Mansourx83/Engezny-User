import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gradution_project2/app_routes.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/firebase_options.dart';
import 'package:gradution_project2/presentation/screens/pages/splash_screen.dart';
import 'package:gradution_project2/presentation/widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AppRouter _appRouter = AppRouter();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Graduation Project',
      theme: ThemeData(
          fontFamily: "LamaSans",
          primaryColor: Colors.blue,
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue,
              cursorColor: Colors.blue,
              selectionHandleColor: Colors.blue)),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const animitedSplashScreenxtends();
            } else {
              return const Navbar();
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      onGenerateRoute: _appRouter.generateRoute,
    );
  }
}
