library photo_view;

import 'dart:typed_data';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/src/photo_view_computed_scale.dart';
import 'package:photo_view/src/photo_view_image_wrapper.dart';
import 'package:photo_view/src/photo_view_loading_phase.dart';
import 'package:photo_view/src/photo_view_scale_boundaries.dart';
import 'package:photo_view/src/photo_view_scale_state.dart';

export 'package:photo_view/photo_view_gallery.dart';
export 'package:photo_view/src/photo_view_computed_scale.dart';

typedef PhotoViewScaleStateChangedCallback = void Function(PhotoViewScaleState scaleState);
typedef _ImageProviderResolverListener = void Function();

/// A [StatefulWidget] that contains all the photo view rendering elements.
///
/// Internally, the image is rendered within an [Image] widget.
///
/// To use along a hero animation, provide [heroTag] param.
///
/// Sample code:
///
/// ```
/// PhotoView(
///  imageProvider: imageProvider,
///  activityIndicator: new LoadingText(),
///  backgroundDecoration: BoxDecoration(color: Colors.white),
///  minScale: PhotoViewComputedScale.contained,
///  maxScale: 2.0,
///  gaplessPlayback: false,
///  size:MediaQuery.of(context).size,
///  heroTag: "someTag"
/// );
/// ```
///

class PhotoView extends StatefulWidget {
  /// Creates a widget that displays a zoomable image.
  ///
  /// To show an image from the network or from an asset bundle, use their respective
  /// image providers, ie: [AssetImage] or [NetworkImage]
  ///
  /// The [maxScale] and [minScale] arguments may be [double] or a [PhotoViewComputedScale] constant
  ///
  /// Sample using [maxScale] and [minScale]
  ///
  /// ```
  /// PhotoView(
  ///  imageProvider: imageProvider,
  ///  minScale: PhotoViewComputedScale.contained * 1.8,
  ///  maxScale: PhotoViewComputedScale.covered * 1.1
  /// );
  /// ```
  /// [customSize] is used to define the viewPort size in which the image will be
  /// scaled to. This argument is rarely used. By befault is the size that this widget assumes.
  ///
  /// The argument [gaplessPlayback] is used to continue showing the old image
  /// (`true`), or briefly show nothing (`false`), when the [imageProvider]
  /// changes.By default it's set to `false`.
  ///
  /// To use within an hero animation, specify [heroTag]. When [heroTag] is
  /// specified, the image provider retrieval process should be sync.
  ///
  /// Sample using hero animation
  /// ```
  /// // screen1
  ///   ...
  ///   Hero(
  ///     tag: "someTag",
  ///     child: Image.asset(
  ///       "assets/large-image.jpg",
  ///       width: 150.0
  ///     ),
  ///   )
  /// // screen2
  /// ...
  /// child: PhotoView(
  ///   imageProvider: AssetImage("assets/large-image.jpg"),
  ///   heroTag: "someTag",
  /// )
  /// ```
  ///
  const PhotoView({
    Key key,
    @required this.imageProvider,
    @required this.placeholderProvider,
    this.activityIndicator,
    this.minScale,
    this.maxScale,
    this.initialScale,
    this.customSize,
    this.heroTag,
    this.scaleStateChangedCallback,
    this.alignment = Alignment.center,
    this.enableRotation = false,
    this.backgroundDecoration = const BoxDecoration(color: Colors.white12),
  })  : assert(imageProvider != null),
        assert(placeholderProvider != null),
        assert(alignment != null),
        super(key: key);

  PhotoView.memoryNetwork({
    Key key,
    @required this.imageProvider,
    @required Uint8List placeholder,
    this.activityIndicator,
    this.minScale,
    this.maxScale,
    this.initialScale = 1.0,
    this.customSize,
    this.heroTag,
    this.scaleStateChangedCallback,
    this.alignment = Alignment.center,
    this.enableRotation = false,
    this.backgroundDecoration = const BoxDecoration(color: Colors.white12),
  })  : assert(imageProvider != null),
        assert(placeholder != null),
        assert(alignment != null),
        placeholderProvider = MemoryImage(placeholder, scale: initialScale),
        super(key: key);

  PhotoView.assetNetwork({
    Key key,
    @required this.imageProvider,
    @required String placeholder,
    AssetBundle bundle,
    this.activityIndicator,
    this.minScale,
    this.maxScale,
    this.initialScale = 1.0,
    this.customSize,
    this.heroTag,
    this.scaleStateChangedCallback,
    this.alignment = Alignment.center,
    this.enableRotation = false,
    this.backgroundDecoration = const BoxDecoration(color: Colors.white12),
  })  : assert(imageProvider != null),
        assert(placeholder != null),
        assert(alignment != null),
        placeholderProvider = initialScale != null
            ? ExactAssetImage(placeholder, bundle: bundle, scale: initialScale)
            : AssetImage(placeholder, bundle: bundle),
        super(key: key);

  /// Given a [imageProvider] it resolves into an zoomable image widget using. It
  /// is required
  final ImageProvider imageProvider;

  /// Given a [placeholderProvider] it resolves into an placeholder before zoomable image widget will be configured.
  /// It is required
  final ImageProvider placeholderProvider;

  /// While [imageProvider] is not resolved, [activityIndicator] is build by [PhotoView]
  /// into the screen, by default it is a centered [CircularProgressIndicator]
  final WidgetBuilder activityIndicator;

  /// Widget alignment inside of page, Centered by default.
  final AlignmentGeometry alignment;

  /// Changes the background behind image, defaults to `Colors.black`.
  final Decoration backgroundDecoration;

  /// Defines the minimal size in which the image will be allowed to assume, it
  /// is proportional to the original image size. Can be either a double (absolute value) or a
  /// [PhotoViewComputedScale], that can be multiplied by a double
  final dynamic minScale;

  /// Defines the maximal size in which the image will be allowed to assume, it
  /// is proportional to the original image size. Can be either a double (absolute value) or a
  /// [PhotoViewComputedScale], that can be multiplied by a double
  final dynamic maxScale;

  /// Defines the initial size in which the image will be assume in the mounting of the component, it
  /// is proportional to the original image size. Can be either a double (absolute value) or a
  /// [PhotoViewComputedScale], that can be multiplied by a double
  final dynamic initialScale;

  /// Defines the size of the scaling base of the image inside [PhotoView],
  /// by default it is `MediaQuery.of(context).size`.
  final Size customSize;

  /// Assists the activation of a hero animation within [PhotoView]
  final Object heroTag;

  final PhotoViewScaleStateChangedCallback scaleStateChangedCallback;

  final bool enableRotation;

  @override
  State<StatefulWidget> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> with AfterLayoutMixin<PhotoView> {
  _ImageProviderResolver _imageResolver;
  _ImageProviderResolver _placeholderResolver;

  PhotoViewScaleState _scaleState;
  Size _size;

  PhotoViewLoadingPhase _phase = PhotoViewLoadingPhase.start;

  PhotoViewLoadingPhase get phase => _phase;

  ImageProvider get provider =>
      _isShowingPlaceholder ? widget.placeholderProvider : widget.imageProvider;

  @override
  void initState() {
    _imageResolver = _ImageProviderResolver(state: this, resolverListener: _updatePhase);
    _placeholderResolver = _ImageProviderResolver(
        state: this,
        resolverListener: () {
          setState(() {
            // Trigger rebuild to display the placeholder image
          });
        });
    _scaleState = PhotoViewScaleState.initial;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(PhotoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider ||
        widget.placeholderProvider != widget.placeholderProvider) {
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.imageProvider);

    // No need to resolve the placeholder if we are past the placeholder stage.
    if (_isShowingPlaceholder) {
      _placeholderResolver.resolve(widget.placeholderProvider);
    }

    if (_phase == PhotoViewLoadingPhase.start) {
      _updatePhase();
    }
  }

  void _updatePhase() {
    setState(() {
      switch (_phase) {
        case PhotoViewLoadingPhase.start:
          _phase = _imageResolver._imageInfo != null
              ? PhotoViewLoadingPhase.completed
              : PhotoViewLoadingPhase.loading;
          break;
        case PhotoViewLoadingPhase.loading:
          if (_imageResolver._imageInfo != null) {
            _phase = PhotoViewLoadingPhase.completed;
          }
          break;
        case PhotoViewLoadingPhase.completed:
          // Nothing to do.
          break;
      }
    });
  }

  @override
  void dispose() {
    _imageResolver.stopListening();
    _placeholderResolver.stopListening();
    super.dispose();
  }

  bool get _isShowingPlaceholder {
    assert(_phase != null);
    return _phase != PhotoViewLoadingPhase.completed;
  }

  ImageInfo get _imageInfo {
    return _isShowingPlaceholder ? _placeholderResolver._imageInfo : _imageResolver._imageInfo;
  }

  void setNextScaleState(PhotoViewScaleState newScaleState) {
    setState(() {
      _scaleState = newScaleState;
    });
    widget.scaleStateChangedCallback != null
        ? widget.scaleStateChangedCallback(newScaleState)
        : null;
  }

  void onStartPanning() {
    setState(() {
      _scaleState = PhotoViewScaleState.zooming;
    });
    widget.scaleStateChangedCallback != null
        ? widget.scaleStateChangedCallback(PhotoViewScaleState.zooming)
        : null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      _size = context.size;
    });
  }

  Size get _computedSize => widget.customSize ?? _size ?? MediaQuery.of(context).size;

  @override
  Widget build(BuildContext context) {
    assert(_phase != PhotoViewLoadingPhase.start);

    final Widget imageWrapper = PhotoViewImageWrapper(
      setNextScaleState: setNextScaleState,
      onStartPanning: onStartPanning,
      imageProvider: _isShowingPlaceholder ? widget.placeholderProvider : widget.imageProvider,
      childSize: _computedSize,
      scaleState: _scaleState,
      backgroundDecoration: widget.backgroundDecoration,
      size: _computedSize,
      enableRotation: widget.enableRotation,
      enableScaling: !_isShowingPlaceholder,
      scaleBoundaries: ScaleBoundaries(
        widget.minScale ?? 0.0,
        widget.maxScale ?? double.infinity,
        widget.initialScale ?? PhotoViewComputedScale.contained,
        childSize: _computedSize,
        size: _computedSize,
      ),
      heroTag: widget.heroTag,
    );

    return widget.activityIndicator != null && _isShowingPlaceholder
        ? Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              imageWrapper,
              widget.activityIndicator(context),
            ],
          )
        : imageWrapper;
  }
}

class _ImageProviderResolver {
  _ImageProviderResolver({
    @required this.state,
    @required this.resolverListener,
  });

  final _PhotoViewState state;
  final _ImageProviderResolverListener resolverListener;
  ImageStream _imageStream;
  ImageInfo _imageInfo;

  PhotoView get widget => state.widget;

  void resolve(ImageProvider provider) {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = provider.resolve(const ImageConfiguration());
    assert(_imageStream != null);

    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  /// [ImageListener] function
  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;
    resolverListener();
  }

  /// Unsubscribe from stream
  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}
