library photo_view_gallery;

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/src/photo_view_scale_state.dart';

typedef PhotoViewGalleryPageChangedCallback = void Function(int index);

class PhotoViewGallery extends StatefulWidget {
  const PhotoViewGallery({
    Key key,
    @required this.pageOptions,
    this.activityIndicator,
    this.backgroundDecoration = const BoxDecoration(color: const Color.fromRGBO(0, 0, 0, 1.0)),
    this.gaplessPlayback = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
  }) : super(key: key);

  final List<PhotoViewGalleryPageOptions> pageOptions;
  final WidgetBuilder activityIndicator;
  final Decoration backgroundDecoration;
  final bool gaplessPlayback;
  final PageController pageController;
  final PhotoViewGalleryPageChangedCallback onPageChanged;
  final PhotoViewScaleStateChangedCallback scaleStateChangedCallback;

  @override
  State<StatefulWidget> createState() {
    return _PhotoViewGalleryState();
  }
}

class _PhotoViewGalleryState extends State<PhotoViewGallery> {
  PageController _controller;
  bool _locked;

  @override
  void initState() {
    _controller = widget.pageController ?? PageController();
    _locked = false;
    super.initState();
  }

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    setState(() {
      _locked = scaleState != PhotoViewScaleState.initial;
    });
    widget.scaleStateChangedCallback != null ? widget.scaleStateChangedCallback(scaleState) : null;
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page.floor() : 0;
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      onPageChanged: widget.onPageChanged,
      itemCount: widget.pageOptions.length,
      itemBuilder: _buildItem,
      physics: _locked ? const NeverScrollableScrollPhysics() : null,
    );
  }

  Widget _buildItem(context, int index) {
    final pageOption = widget.pageOptions[index];
    return PhotoView(
      key: ObjectKey(index),
      imageProvider: pageOption.imageProvider,
      placeholderProvider: pageOption.initialScale != null
          ? ExactAssetImage(pageOption.placeholder, scale: pageOption.initialScale)
          : AssetImage(pageOption.placeholder),
      activityIndicator: widget.activityIndicator,
      backgroundDecoration: widget.backgroundDecoration,
      minScale: pageOption.minScale,
      maxScale: pageOption.maxScale,
      initialScale: pageOption.initialScale,
      heroTag: pageOption.heroTag,
      scaleStateChangedCallback: scaleStateChangedCallback,
    );
  }
}

class PhotoViewGalleryPageOptions {
  PhotoViewGalleryPageOptions({
    Key key,
    @required this.imageProvider,
    @required this.placeholder,
    this.heroTag,
    this.minScale,
    this.maxScale,
    this.initialScale,
  });

  final ImageProvider imageProvider;
  final String placeholder;
  final Object heroTag;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
}
