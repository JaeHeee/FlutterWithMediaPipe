import 'anchors.dart';
import 'decode_box.dart';
import 'detection.dart';
import 'options.dart';

List<Detection> convertToDetections(
    List<double> rawBoxes,
    List<Anchor> anchors,
    List<double> detectionScores,
    List<int> detectionClasses,
    OptionsFace options) {
  var outputDetections = <Detection>[];
  for (var i = 0; i < options.numBoxes; i++) {
    if (detectionScores[i] < options.minScoreThresh) continue;
    var boxOffset = 0;
    var boxData = decodeBox(rawBoxes, i, anchors, options);

    var detection = convertToDetection(
        boxData[boxOffset + 0],
        boxData[boxOffset + 1],
        boxData[boxOffset + 2],
        boxData[boxOffset + 3],
        detectionScores[i],
        detectionClasses[i],
        options.flipVertically);
    outputDetections.add(detection);
  }
  return outputDetections;
}

Detection convertToDetection(
  double boxYMin,
  double boxXMin,
  double boxYMax,
  double boxXMax,
  double score,
  int classID,
  bool flipVertically,
) {
  var yMin = flipVertically ? 1.0 - boxYMax : boxYMin;
  var width = boxXMax;
  var height = boxYMax;

  return Detection(
    score,
    classID,
    boxXMin,
    yMin,
    width,
    height,
  );
}
