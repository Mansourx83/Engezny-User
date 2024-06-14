import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gradution_project2/presentation/screens/pages/profie_page.dart';
import 'package:gradution_project2/presentation/screens/pages/rate_page.dart';
import 'package:gradution_project2/presentation/screens/pages/report_page.dart';
import 'package:gradution_project2/presentation/screens/pages/transport_details.dart';

import '../screens/pages/home_page.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      const HomePage(),
      const TransportDetails(),
      const RatePage(),
      const ReportPage(),
      const ProfilePage(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          animationDuration: const Duration(milliseconds: 600),
          backgroundColor: Colors.white,
          buttonBackgroundColor: Colors.white,
          color: const Color(0xff2074EF),
          height: 50,
          index: currentIndex,
          items: const [
            Icon(Icons.home_outlined, size: 30),
            Icon(Icons.location_on_outlined, size: 30),
            Icon(Icons.star_border, size: 30),
            Icon(Icons.announcement_outlined, size: 30),
            Icon(Icons.person_2_outlined, size: 30),
          ],
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
        body: screens[currentIndex],
      ),
    );
  }
}
