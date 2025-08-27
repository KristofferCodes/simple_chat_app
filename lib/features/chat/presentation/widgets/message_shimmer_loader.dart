import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MessageShimmerLoader extends StatelessWidget {
  final bool isMe;
  final bool isImageMessage;

  const MessageShimmerLoader({
    Key? key,
    required this.isMe,
    this.isImageMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isMe ? _buildMyMessageGradient() : null,
        color: isMe ? null : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isImageMessage ? 4 : 16,
              vertical: isImageMessage ? 4 : 12,
            ),
            child: isImageMessage ? _buildImagePlaceholder() : _buildTextPlaceholder(),
          ),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                child: Shimmer.fromColors(
                  baseColor: isMe 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey[300]!,
                  highlightColor: isMe 
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey[100]!,
                  direction: ShimmerDirection.ltr,
                  period: Duration(milliseconds: 1500),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMe 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      isImageMessage ? 'Uploading...' : 'Sending...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Container(
            height: 12,
            width: 60,
            color: Colors.transparent,
            margin: EdgeInsets.only(bottom: 4),
          ),
        Container(
          height: 16,
          width: 150,
          color: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Container(
            height: 12,
            width: 60,
            color: Colors.transparent,
            margin: EdgeInsets.all(8),
          ),
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  LinearGradient _buildMyMessageGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2196F3),
        Color(0xFF1976D2),
      ],
    );
  }
}

class PulsingMessageLoader extends StatefulWidget {
  final Widget child;
  final bool isPulsing;

  const PulsingMessageLoader({
    Key? key,
    required this.child,
    this.isPulsing = true,
  }) : super(key: key);

  @override
  State<PulsingMessageLoader> createState() => _PulsingMessageLoaderState();
}

class _PulsingMessageLoaderState extends State<PulsingMessageLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingMessageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}