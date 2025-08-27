import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/repository/firebase_chat_repository.dart';

class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  String? _base64Data;
  bool _isLoading = true;
  bool _hasError = false;
  bool _imageExpired = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  void _loadImage() {
    if (!widget.imageUrl.startsWith('cache:')) {
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
        _imageExpired = false;
      });

      final imageId = widget.imageUrl.replaceFirst('cache:', '');
      final base64Data = FirebaseChatRepository.getCachedImage(imageId);

      if (mounted) {
        if (base64Data != null) {
          setState(() {
            _base64Data = base64Data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _imageExpired = true;
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
      return Stack(
        children: [
          Image.memory(
            imageBytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return widget.errorWidget ?? _buildDefaultErrorWidget();
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Temp',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        border: Border.all(
          color: _imageExpired ? Colors.orange[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _imageExpired ? Icons.access_time : Icons.error_outline,
            color: _imageExpired ? Colors.orange[400] : Colors.grey[500],
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            _imageExpired 
                ? 'Image expired\n(session ended)'
                : 'Failed to load image',
            style: TextStyle(
              color: _imageExpired ? Colors.orange[600] : Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          if (_imageExpired) ...[
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!, width: 0.5),
              ),
              child: Text(
                'Images are temporary',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CacheStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = FirebaseChatRepository.getCacheStats();
    
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, size: 20, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Image Cache Stats',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Images Cached',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${stats['totalImages']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Memory Used',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${stats['totalSizeMB']} MB',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    FirebaseChatRepository.clearImageCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Image cache cleared'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.clear_all, size: 16),
                  label: Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}