import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradution_project2/bussines_logic/cubit/phone_auth_cubit.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/screens/auth/login_screen.dart';
import 'package:gradution_project2/presentation/screens/auth/otp_screen.dart';
import 'package:gradution_project2/presentation/screens/pages/choselogin.dart';
import 'package:gradution_project2/presentation/screens/pages/home_page.dart';
import 'package:gradution_project2/presentation/screens/pages/splash_screen.dart';
import 'package:gradution_project2/presentation/widgets/navbar.dart';

class AppRouter {
  PhoneAuthCubit? phoneAuthCubit;

  AppRouter() {
    phoneAuthCubit = PhoneAuthCubit();
  }

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/': // تأكد من إضافة هذه الحالة للتعامل مع المسار الافتراضي
        return MaterialPageRoute(
            builder: (_) => const animitedSplashScreenxtends());
      case homePage:
        return MaterialPageRoute(
            builder: (_) => BlocProvider<PhoneAuthCubit>.value(
                value: phoneAuthCubit!, child: const HomePage()));
      case loginScreen:
        return MaterialPageRoute(
            builder: (_) => BlocProvider<PhoneAuthCubit>.value(
                value: phoneAuthCubit!, child: const LoginScreen()));
      case otpScreen:
        final phoneNumber = settings.arguments;
        return MaterialPageRoute(
            builder: (_) => BlocProvider.value(
                value: phoneAuthCubit!,
                child: OtpScreen(phoneNumber: phoneNumber.toString())));
      case navBar:
        return MaterialPageRoute(
            builder: (_) => BlocProvider<PhoneAuthCubit>.value(
                value: phoneAuthCubit!, child: const Navbar()));
      case choseLogin:
        return MaterialPageRoute(
            builder: (_) => BlocProvider<PhoneAuthCubit>.value(
                value: phoneAuthCubit!, child: const ChoseLogin()));
      case animitedSplashScreen:
        return MaterialPageRoute(
            builder: (_) => BlocProvider<PhoneAuthCubit>.value(
                value: phoneAuthCubit!,
                child: const animitedSplashScreenxtends()));
      default:
        return MaterialPageRoute(
            builder: (_) => const animitedSplashScreenxtends());
    }
  }
}
