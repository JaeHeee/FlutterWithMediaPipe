import 'dart:ui';

import 'package:flutter/material.dart';

class PosePainter extends CustomPainter {
  final List<Offset> points;
  final double ratio;

  PosePainter({
    required this.points,
    required this.ratio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isNotEmpty) {
      var pointPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 8;
      var headPaint = Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 2;
      var leftPaint = Paint()
        ..color = Colors.lightBlue
        ..strokeWidth = 2;
      var rightPaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 2;
      var bodyPaint = Paint()
        ..color = Colors.pink
        ..strokeWidth = 2;

      canvas.drawPoints(
        PointMode.points,
        points.sublist(0, 34).map((point) => point * ratio).toList(),
        pointPaint,
      );

      canvas.drawPoints(
        PointMode.polygon,
        [
          points[8],
          points[6],
          points[5],
          points[4],
          points[0],
          points[1],
          points[2],
          points[3],
          points[7],
        ].map((point) => point * ratio).toList(),
        headPaint,
      );
      canvas.drawPoints(
        PointMode.polygon,
        [
          points[10],
          points[9],
        ].map((point) => point * ratio).toList(),
        headPaint,
      );

      canvas.drawPoints(
        PointMode.polygon,
        [
          points[12],
          points[14],
          points[16],
          points[18],
          points[20],
          points[16],
        ].map((point) => point * ratio).toList(),
        leftPaint,
      );
      canvas.drawPoints(
        PointMode.polygon,
        [
          points[16],
          points[22],
        ].map((point) => point * ratio).toList(),
        leftPaint,
      );
      canvas.drawPoints(
        PointMode.polygon,
        [
          points[24],
          points[26],
          points[28],
          points[32],
          points[30],
          points[28],
        ].map((point) => point * ratio).toList(),
        leftPaint,
      );

      canvas.drawPoints(
        PointMode.polygon,
        [
          points[11],
          points[13],
          points[15],
          points[17],
          points[19],
          points[15],
        ].map((point) => point * ratio).toList(),
        rightPaint,
      );
      canvas.drawPoints(
        PointMode.polygon,
        [
          points[15],
          points[21],
        ].map((point) => point * ratio).toList(),
        rightPaint,
      );
      canvas.drawPoints(
        PointMode.polygon,
        [
          points[23],
          points[25],
          points[27],
          points[29],
          points[31],
          points[27],
        ].map((point) => point * ratio).toList(),
        rightPaint,
      );

      canvas.drawPoints(
        PointMode.polygon,
        [
          points[11],
          points[12],
          points[24],
          points[23],
          points[11],
        ].map((point) => point * ratio).toList(),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
