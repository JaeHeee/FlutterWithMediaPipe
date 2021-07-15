class AnchorOption {
  int inputSizeWidth;
  int inputSizeHeight;
  final double minScale;
  final double maxScale;
  final double anchorOffsetX;
  final double anchorOffsetY;
  final int numLayers;
  final List<int> featureMapWidth;
  final List<int> featureMapHeight;
  final List<int> strides;
  final List<double> aspectRatios;
  final bool reduceBoxesInLowestLayer;
  final double interpolatedScaleAspectRatio;
  final bool fixedAnchorSize;

  AnchorOption({
    this.inputSizeWidth,
    this.inputSizeHeight,
    this.minScale,
    this.maxScale,
    this.anchorOffsetX,
    this.anchorOffsetY,
    this.numLayers,
    this.featureMapWidth,
    this.featureMapHeight,
    this.strides,
    this.aspectRatios,
    this.reduceBoxesInLowestLayer,
    this.interpolatedScaleAspectRatio,
    this.fixedAnchorSize,
  });

  int get stridesSize {
    return strides.length;
  }

  int get aspectRatiosSize {
    return aspectRatios.length;
  }

  int get featureMapHeightSize {
    return featureMapHeight.length;
  }

  int get featureMapWidthSize {
    return featureMapWidth.length;
  }
}

class Anchor {
  final double xCenter;
  final double yCenter;
  final double h;
  final double w;
  Anchor(this.xCenter, this.yCenter, this.h, this.w);
}
