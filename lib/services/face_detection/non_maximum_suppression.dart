import 'package:scidart/numdart.dart';

import 'detection.dart';

List<Detection> nonMaximumSuppression(
  List<Detection> detections,
  double threshold,
) {
  if (detections.isEmpty) return [];
  var x1 = <double>[];
  var x2 = <double>[];
  var y1 = <double>[];
  var y2 = <double>[];
  var s = <double>[];

  for (var detection in detections) {
    x1.add(detection.xMin);
    x2.add(detection.xMin + detection.width);
    y1.add(detection.yMin);
    y2.add(detection.yMin + detection.height);
    s.add(detection.score);
  }

  var x11 = Array(x1);
  var x22 = Array(x2);
  var y11 = Array(y1);
  var y22 = Array(y2);

  var area = (x22 - x11) * (y22 - y11);
  var I = _quickSort(s);

  var positions = <int>[];
  for (var element in I) {
    positions.add(s.indexOf(element));
  }

  var pick = <int>[];
  while (I.isNotEmpty) {
    var ind0 = positions.sublist(positions.length - 1, positions.length);
    var ind1 = positions.sublist(0, positions.length - 1);

    var xx1 = _maximum(_itemIndex(x11, ind0)[0], _itemIndex(x11, ind1));
    var yy1 = _maximum(_itemIndex(y11, ind0)[0], _itemIndex(y11, ind1));
    var xx2 = _minimum(_itemIndex(x22, ind0)[0], _itemIndex(x22, ind1));
    var yy2 = _minimum(_itemIndex(y22, ind0)[0], _itemIndex(y22, ind1));
    var w = _maximum(0.0, xx2 - xx1);
    var h = _maximum(0.0, yy2 - yy1);
    var inter = w * h;
    var o = inter /
        (_sum(_itemIndex(area, ind0)[0], _itemIndex(area, ind1)) - inter);

    pick.add(ind0[0]);
    I = o.where((element) => element <= threshold).toList();
  }
  return [detections[pick[0]]];
}

Array _sum(double a, Array b) {
  var temp = <double>[];
  for (var element in b) {
    temp.add(a + element);
  }
  return Array(temp);
}

Array _maximum(double value, Array itemIndex) {
  var temp = <double>[];
  for (var element in itemIndex) {
    if (value > element) {
      temp.add(value);
    } else {
      temp.add(element);
    }
  }
  return Array(temp);
}

Array _minimum(double value, Array itemIndex) {
  var temp = <double>[];
  for (var element in itemIndex) {
    if (value < element) {
      temp.add(value);
    } else {
      temp.add(element);
    }
  }
  return Array(temp);
}

Array _itemIndex(Array item, List<int> positions) {
  var temp = <double>[];
  for (var element in positions) {
    temp.add(item[element]);
  }
  return Array(temp);
}

List<double> _quickSort(List<double> a) {
  if (a.length <= 1) return a;

  var pivot = a[0];
  var less = <double>[];
  var more = <double>[];
  var pivotList = <double>[];

  for (var i in a) {
    if (i.compareTo(pivot) < 0) {
      less.add(i);
    } else if (i.compareTo(pivot) > 0) {
      more.add(i);
    } else {
      pivotList.add(i);
    }
  }

  less = _quickSort(less);
  more = _quickSort(more);

  less.addAll(pivotList);
  less.addAll(more);
  return less;
}
