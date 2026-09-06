import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'photo_gallery_viewer_screen.dart';

/// Shows the first photo attached to a job request, scaled to its real
/// aspect ratio (not stretched/cropped to a fixed box) up to [maxHeight].
/// A "+N" overlay appears if more than one photo was attached. Tapping
/// opens a full-screen swipeable viewer (with pinch-zoom and left/right
/// arrows) starting at this photo.
class JobPhotoPreview extends StatefulWidget {
  final List<String> photoPaths;
  final double maxHeight;

  const JobPhotoPreview({super.key, required this.photoPaths, this.maxHeight = 220});

  @override
  State<JobPhotoPreview> createState() => _JobPhotoPreviewState();
}

class _JobPhotoPreviewState extends State<JobPhotoPreview> {
  double? _aspectRatio;
  String? _resolvedFor;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  @override
  void didUpdateWidget(covariant JobPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final firstPath = widget.photoPaths.isEmpty ? null : widget.photoPaths.first;
    if (firstPath != _resolvedFor) {
      _aspectRatio = null;
      _resolveSize();
    }
  }

  void _resolveSize() {
    if (widget.photoPaths.isEmpty) return;
    final path = widget.photoPaths.first;
    _resolvedFor = path;

    final provider = FileImage(File(path));
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (!mounted || _resolvedFor != path) return;
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (h <= 0) return;
      setState(() => _aspectRatio = w / h);
    }, onError: (error, stackTrace) {
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  void _openViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhotoGalleryViewerScreen(photoPaths: widget.photoPaths, initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoPaths.isEmpty) return const SizedBox.shrink();

    // Reasonable placeholder ratio while the real dimensions are still
    // being resolved — swapped out the instant they're known.
    final ratio = _aspectRatio ?? (4 / 3);

    return GestureDetector(
      onTap: _openViewer,
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: AspectRatio(
              aspectRatio: ratio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.photoPaths.first),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.background,
                      child: Icon(Icons.broken_image_outlined, color: AppColors.textdark.withValues(alpha: 0.55)),
                    ),
                  ),
                  if (widget.photoPaths.length > 1)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '+${widget.photoPaths.length - 1}',
                          style: TextStyle(color: AppColors.textmedium, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}