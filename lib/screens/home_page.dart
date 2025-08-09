import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/events_screen.dart';
import 'package:flutter_application_1/screens/posts_screen.dart';
import 'package:flutter_application_1/screens/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static var routeName = "/home";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var now = DateTime.now();

  var selectedIndex = 0;

  static List<Widget> screens = <Widget>[
    PostsScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    // var nav = Navigator.of(context);

    // Each screen in the bottom navigation bar has different app bars

    List<PreferredSizeWidget?> appBars = [
      AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Text(
          "EcoExchangeSg",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: texttheme.headlineMedium!.fontSize,
          ),
        ),
        leading: Container(
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Center(
            child: Image.asset("assets/images/logo.png", width: 35, height: 35),
          ),
        ),
      ),
      AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Text(
          "Events",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: texttheme.headlineMedium!.fontSize,
          ),
        ),
        leading: Container(
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Center(
            child: Image.asset("assets/images/logo.png", width: 35, height: 35),
          ),
        ),
      ),
      null,
    ];

    return Scaffold(
      appBar: appBars[selectedIndex],
      body: screens[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Theme.of(context).colorScheme.primary,

        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Events',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
