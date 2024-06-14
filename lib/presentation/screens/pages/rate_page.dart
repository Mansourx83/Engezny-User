import 'package:flutter/material.dart';
import 'package:gradution_project2/presentation/screens/pages/choselogin.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:gradution_project2/presentation/widgets/rate_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatePage extends StatelessWidget {
  const RatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: _buildBody(context, user),
    );
  }

  Widget _buildBody(BuildContext context, User? user) {
    return user != null
        ? const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: ConstantWidget(),
                  ),
                  SizedBox(height: 4),
                  RatingWidget(),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const ConstantWidget(),
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    const Text(
                      "لا يمكنك ارسال تقييم للسيارات يجب عليك تسجيل الدخول اولا لارسال تقييمك",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 20),
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
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) {
                                    return const ChoseLogin();
                                  }),
                                  (route) => false,
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "تسجيل الدخول",
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
                  ],
                )
              ],
            ),
          );
  }
}
