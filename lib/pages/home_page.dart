import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/data.dart';
import 'camera_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        setState(() {
          _currentPageValue = _pageController.page!;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Select Your Model',
        style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(28),
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Stack _buildBody() {
    return Stack(
      children: [
        _buildBackgroundImage(),
        _buildModelPageView(),
      ],
    );
  }

  Center _buildModelPageView() {
    return Center(
      child: Container(
        height: ScreenUtil().setHeight(450.0),
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: models.length,
          itemBuilder: (context, index) {
            var scale = (_currentPageValue - index).abs();
            return _buildModelCard(index, scale);
          },
        ),
      ),
    );
  }

  InkWell _buildModelCard(int index, double scale) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CameraPage(
                title: models[index]['title']!,
                modelName: models[index]['model']!,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          image: DecorationImage(
            image: AssetImage(models[index]['image']!),
            fit: BoxFit.cover,
          ),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: ScreenUtil().setWidth(10.0),
          vertical: ScreenUtil().setHeight(30.0) * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                ),
              ),
              padding: EdgeInsets.all(ScreenUtil().setWidth(16.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    models[index]['title']!,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ScreenUtil().setSp(20.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(8.0),
                  ),
                  Text(
                    models[index]['text']!,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ScreenUtil().setSp(12.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBackgroundImage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            models[_currentPageValue.round()]['image']!,
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5.0,
          sigmaY: 5.0,
        ),
        child: Container(
          color: Colors.black.withOpacity(0.15),
        ),
      ),
    );
  }
}
