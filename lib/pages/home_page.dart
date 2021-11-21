import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/data.dart';
import 'widgets/model_card.dart';

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
            return ModelCard(
              index: index,
              scale: scale,
            );
          },
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
