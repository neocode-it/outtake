import 'package:flutter/material.dart';

class CustomImageViewer extends StatefulWidget {
  final List<ImageProvider> imageProviders;
  final int initialIndex;

  const CustomImageViewer({
    super.key,
    required this.imageProviders,
    this.initialIndex = 0,
  });

  @override
  State<CustomImageViewer> createState() => _CustomImageViewerState();
}

class _CustomImageViewerState extends State<CustomImageViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _isZoomed = false;

  int _pointerCount = 0;
  int? _swipePointerId;
  double? _swipeStartX;
  static const _swipeThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount == 1 && !_isZoomed) {
      _swipePointerId = event.pointer;
      _swipeStartX = event.position.dx;
    } else {
      _swipePointerId = null;
      _swipeStartX = null;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_pointerCount > 0) _pointerCount--;

    if (event.pointer == _swipePointerId && _swipeStartX != null) {
      final dx = event.position.dx - _swipeStartX!;
      if (dx < -_swipeThreshold &&
          _currentPage < widget.imageProviders.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (dx > _swipeThreshold && _currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    if (_pointerCount == 0) {
      _swipePointerId = null;
      _swipeStartX = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_pointerCount > 0) _pointerCount--;

    if (_pointerCount == 0) {
      _swipePointerId = null;
      _swipeStartX = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.imageProviders.length,
          onPageChanged: (index) {
            _currentPage = index;
            _isZoomed = false;
          },
          itemBuilder: (context, index) {
            return _ZoomableImage(
              key: ValueKey(index),
              imageProvider: widget.imageProviders[index],
              onScaleChanged: (scale) {
                final zoomed = scale > 1.05;
                if (zoomed != _isZoomed) {
                  setState(() {
                    _isZoomed = zoomed;
                  });
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final void Function(double scale) onScaleChanged;

  const _ZoomableImage({
    super.key,
    required this.imageProvider,
    required this.onScaleChanged,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation!.value;
        widget
            .onScaleChanged(_transformationController.value.getMaxScaleOnAxis());
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();

    double targetScale = 1.0;

    bool isPreset1 = (currentScale - 2.5).abs() < 0.1;
    bool isPreset2 = (currentScale - 5.0).abs() < 0.1;

    if (currentScale > 1.05 && !isPreset1 && !isPreset2) {
      targetScale = 1.0;
    } else if (currentScale < 1.9) {
      targetScale = 2.5;
    } else if (currentScale < 3.9) {
      targetScale = 5.0;
    } else {
      targetScale = 1.0;
    }

    if (targetScale == 1.0) {
      _animateToMatrix(Matrix4.identity());
      return;
    }

    final Offset tapPosition = _doubleTapDetails!.localPosition;
    final double scaleChange = targetScale / currentScale;

    final Matrix4 zoomMatrix = Matrix4.identity()
      ..translate(tapPosition.dx, tapPosition.dy)
      ..scale(scaleChange)
      ..translate(-tapPosition.dx, -tapPosition.dy);

    final Matrix4 endMatrix = zoomMatrix * currentMatrix;

    _animateToMatrix(endMatrix);
  }

  void _animateToMatrix(Matrix4 endMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          onInteractionUpdate: (details) {
            widget.onScaleChanged(
              _transformationController.value.getMaxScaleOnAxis(),
            );
          },
          child: Image(
            image: widget.imageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
