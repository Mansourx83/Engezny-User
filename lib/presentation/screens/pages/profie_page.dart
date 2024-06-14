import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gradution_project2/bussines_logic/cubit/phone_auth_cubit.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userEmail;
  String? userPhoneNumber;

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      Future.delayed(Duration.zero, () {
        print(userEmail);
        print(userPhoneNumber);
      });
    });
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        userEmail = user.email;
        userPhoneNumber = user.phoneNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PhoneAuthCubit(),
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  const ConstantWidget(),
                  const SizedBox(
                    height: 60,
                  ),
                  if (userEmail != null)
                    Text(
                      'المستخدم: $userEmail',
                      style: const TextStyle(fontSize: 18),
                    ),
                  if (userPhoneNumber != null)
                    Text(
                      'رقم هاتفك: $userPhoneNumber',
                      style: const TextStyle(fontSize: 24),
                    ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Developed by"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPersonTile(
                                  context,
                                  'Fares Ayman',
                                  'Faresayman33233@gmail.com',
                                  '+201112814281',
                                  'https://www.facebook.com/profile.php?id=100009629592204&mibextid=ZbWKwL',
                                ),
                                _buildPersonTile(
                                  context,
                                  'Mina Fayez ',
                                  'minafayezsho8l@gmail.com',
                                  '+201204024225',
                                  'https://www.facebook.com/profile.php?id=100002668343042&mibextid=YMEMSu',
                                ),
                                _buildPersonTile(
                                  context,
                                  'Waleed shaaban',
                                  'waleedshaaban827@gmail.com',
                                  '+201011858212',
                                  'https://www.facebook.com/profile.php?id=100009629592204&mibextid=ZbWKwL',
                                ),
                                _buildPersonTile(
                                  context,
                                  'Youssef Mohammed',
                                  'yousaf83000@gmail.com',
                                  '+201158465425',
                                  'https://www.facebook.com/MANSOUR2001?mibextid=ZbWKwL',
                                ),
                                _buildPersonTile(
                                  context,
                                  'Ahmed Ataf',
                                  'atfa749@gmail.com',
                                  '+201098419123',
                                  'https://www.facebook.com/profile.php?id=100014365413915&mibextid=ZbWKwL',
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'إغلاق',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text(
                      "Contact Us",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () async {
                      final phoneAuthCubit = PhoneAuthCubit();
                      final googleSignIn = GoogleSignIn();
                      try {
                        await googleSignIn.disconnect();
                      } catch (error) {}
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (error) {}
                      await phoneAuthCubit.logOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        choseLogin,
                        (route) => false,
                      );
                    },
                    icon:
                        const Icon(Icons.logout_outlined, color: Colors.white),
                    label: const Text(
                      "تسجيل الخروج",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonTile(BuildContext context, String name, String email,
      String phone, String facebookUrl) {
    return ListTile(
      title: Text(name),
      subtitle: const Text("اضغط للتفاصيل"),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(child: Text(name)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      String url = 'mailto:$email';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.email),
                        SizedBox(width: 8),
                        Text(
                          'البريد الإلكتروني',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      String url = 'https://wa.me/$phone';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'الواتساب',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      String url =
                          facebookUrl; // يجب أن يكون facebookUrl هو رابط ملف الشخص على Facebook
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.facebook, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'فيسبوك',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
