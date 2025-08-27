import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/repository/firebase_chat_repository.dart';

class FirestoreImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirestoreImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<FirestoreImageWidget> createState() => _FirestoreImageWidgetState();
}

class _FirestoreImageWidgetState extends State<FirestoreImageWidget> {
  String? _base64Data;
  bool _isLoading = true;
  bool _hasError = false;
  final FirebaseChatRepository _repository = FirebaseChatRepository();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(FirestoreImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!widget.imageUrl.startsWith('firestore:')) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final imageId = widget.imageUrl.replaceFirst('firestore:', '');
      final base64Data = await _repository.getImageBase64(imageId);

      if (mounted) {
        if (base64Data != null) {
          setState(() {
            _base64Data = base64Data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    if (_hasError || _base64Data == null) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    try {
      final Uint8List imageBytes = base64Decode(_base64Data!);
      return Image.memory(
        imageBytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    } catch (e) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Loading image...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey[500],
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}