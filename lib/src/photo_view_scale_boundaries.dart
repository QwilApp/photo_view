import 'package:flutter/material.dart';
import 'package:photo_view/src/photo_view_computed_scale.dart';
import 'package:photo_view/src/photo_view_utils.dart';

// ignore_for_file: avoid_as
class ScaleBoundaries {
  ScaleBoundaries(
    this._minScale,
    this._maxScale,
    this._initialScale, {
    @required this.screenSize,
    @required this.imageSize,
  })  : assert(_minScale is double || _minScale is PhotoViewComputedScale),
        assert(_maxScale is double || _maxScale is PhotoViewComputedScale),
        assert(_initialScale is double || _initialScale is PhotoViewComputedScale);

  final dynamic _minScale;
  final dynamic _maxScale;
  final dynamic _initialScale;
  Size screenSize;
  Size imageSize;

  double computeMinScale() {
    if (_minScale == PhotoViewComputedScale.contained) {
      return scaleForContained(size: screenSize, childSize: imageSize) *
          (_minScale as PhotoViewComputedScale).multiplier;
    }
    if (_minScale == PhotoViewComputedScale.covered) {
      return scaleForCovering(size: screenSize, childSize: imageSize) *
          (_minScale as PhotoViewComputedScale).multiplier;
    }
    assert(_minScale >= 0.0);
    return _minScale;
  }

  double computeMaxScale() {
    if (_maxScale == PhotoViewComputedScale.contained) {
      return (scaleForContained(size: screenSize, childSize: imageSize) *
              (_maxScale as PhotoViewComputedScale).multiplier)
          .clamp(computeMinScale(), double.infinity);
    }
    if (_maxScale == PhotoViewComputedScale.covered) {
      return (scaleForCovering(size: screenSize, childSize: imageSize) *
              (_maxScale as PhotoViewComputedScale).multiplier)
          .clamp(computeMinScale(), double.infinity);
    }
    return _maxScale.clamp(computeMinScale(), double.infinity);
  }

  double computeInitialScale() {
    if (_initialScale == PhotoViewComputedScale.contained) {
      return scaleForContained(size: screenSize, childSize: imageSize) *
          (_initialScale as PhotoViewComputedScale).multiplier;
    }
    if (_initialScale == PhotoViewComputedScale.covered) {
      return scaleForCovering(size: screenSize, childSize: imageSize) *
          (_initialScale as PhotoViewComputedScale).multiplier;
    }
    return _initialScale.clamp(computeMinScale(), computeMaxScale());
  }
}
