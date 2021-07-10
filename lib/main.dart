import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        builder: () => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Flutter with Mediapipe',
              theme: ThemeData(
                appBarTheme: const AppBarTheme(
                  elevation: 0.0,
                  color: Colors.transparent,
                ),
              ),
              home: const HomePage(),
            ));
  }
}
