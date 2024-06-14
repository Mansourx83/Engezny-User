import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:gradution_project2/presentation/widgets/navbar.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChoseLogin extends StatefulWidget {
  const ChoseLogin({super.key});

  @override
  _ChoseLoginState createState() => _ChoseLoginState();
}

class _ChoseLoginState extends State<ChoseLogin> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
  }

  Future signInWithGoogle(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // Navigate after successful sign-in
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) {
        return const Navbar();
      }),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBackButton(context);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: isLoading
              ? Center(
                  child: Column(
                    children: [
                      Lottie.asset("asset/images/splash.json"),
                      const CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 200,
                        child: ConstantWidget(),
                      ),
                      const SizedBox(height: 90),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            await Navigator.pushNamed(context, loginScreen);

                            setState(() {
                              isLoading = false;
                            });
                          },
                          icon: const Icon(Icons.phone, color: Colors.white),
                          label: const Text(
                            "تسجيل الدخول باستخدام رقم الهاتف",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              endIndent: 14,
                              color: Colors.blue,
                            ),
                          ),
                          Text("or"),
                          Expanded(
                            child: Divider(
                              indent: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  signInWithGoogle(context);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "asset/images/search.png",
                                      height: 20,
                                    ),
                                    const Text(
                                      "   تسجيل الدخول باستخدام جوجل  ",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              endIndent: 14,
                              color: Colors.blue,
                            ),
                          ),
                          Text("or"),
                          Expanded(
                            child: Divider(
                              indent: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () {
                                  // Loading while signing in as a guest
                                  setState(() {
                                    isLoading = true;
                                  });
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) {
                                      return const Navbar();
                                    }),
                                    (route) => false,
                                  );

                                  // Update isLoading value after navigation
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      "   الدخول كضيف",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                      const Text(
                        "powered by",
                        style: TextStyle(color: Colors.blue, fontSize: 20),
                      ),
                      const Text(
                        "Engzny Team",
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // إذا لم يكن هناك اتصال بالإنترنت، عرض رسالة تنبيه
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("خطأ في الاتصال بالإنترنت"),
            content: const Text(
              "الرجاء التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.",
              textAlign: TextAlign.right,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("موافق",
                    style: TextStyle(
                      color: Colors.blue,
                    )),
              ),
            ],
          );
        },
      );
    } else {
      print('Internet Connection is available');
    }
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    if (isLoading) {
      return false;
    } else {
      await _logOutOrExitApp(context);
      return true;
    }
  }

  Future<void> _logOutOrExitApp(BuildContext context) async {
    SystemNavigator.pop();
  }
}
