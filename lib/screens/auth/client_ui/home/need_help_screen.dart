import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/common_widgets.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../../data/quote_store.dart';

class NeedHelpScreen extends StatefulWidget {
  /// Called after the request has been successfully uploaded.
  /// Quotes will start arriving on the notification bell shortly after.
  final VoidCallback? onRequestUploaded;

  const NeedHelpScreen({super.key, this.onRequestUploaded});

  @override
  State<NeedHelpScreen> createState() => _NeedHelpScreenState();
}

class _NeedHelpScreenState extends State<NeedHelpScreen> {
  final _problemCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _urgency = 'Normal';
  String? _selectedIssue;

  final List<XFile> _photos = [];
  bool _fetchingLocation = false;
  bool _uploading = false;

  static const List<Map<String, dynamic>> _issues = [
    {'icon': Icons.car_repair, 'label': 'Engine Problem', 'color': Color(0xFFFF9800)},
    {'icon': Icons.album_outlined, 'label': 'Brake Issue', 'color': AppColors.primary},
    {'icon': Icons.tire_repair, 'label': 'Flat Tire', 'color': AppColors.textDark},
    {'icon': Icons.battery_alert_outlined, 'label': 'Battery Dead', 'color': AppColors.green},
    {'icon': Icons.settings_input_component_outlined, 'label': 'Chain Problem', 'color': AppColors.blue},
    {'icon': Icons.electrical_services_outlined, 'label': 'Electrical Issue', 'color': AppColors.yellow},
  ];

  @override
  void dispose() {
    _problemCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Camera / gallery
  // ---------------------------------------------------------------------

  Future<void> _addPhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _photos.add(file));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access camera/gallery: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // ---------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------

  Future<void> _useCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services to continue.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Enable it in Settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _locationCtrl.text =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    } catch (e) {
      _showSnack('Could not get your location: $e');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------

  Future<void> _uploadRequest() async {
    if (_problemCtrl.text.trim().isEmpty) {
      _showSnack('Please describe the problem.');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _showSnack('Please add your location.');
      return;
    }

    setState(() => _uploading = true);

    final request = HelpRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      problem: _problemCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      urgency: _urgency,
      photoPaths: _photos.map((f) => f.path).toList(),
      createdAt: DateTime.now(),
    );

    // Hands the request off to mechanics. Quotes will arrive asynchronously
    // and show up as a badge on the notification bell.
    QuoteNotificationStore.instance.submitRequest(request);

    if (!mounted) return;
    setState(() => _uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request uploaded! Mechanics will send quotes to your notifications 🔔'),
      ),
    );

    widget.onRequestUploaded?.call();

    setState(() {
      _problemCtrl.clear();
      _locationCtrl.clear();
      _selectedIssue = null;
      _photos.clear();
      _urgency = 'Normal';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Describe your motorcycle problem and get matched with nearby mechanics',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),
          const Text('Common Issues',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: _issues.map((issue) {
              final selected = _selectedIssue == issue['label'];
              final color = issue['color'] as Color;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _selectedIssue = issue['label'] as String;
                  _problemCtrl.text = '${issue['label']}: ';
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.08) : AppColors.white,
                    border: Border.all(
                      color: selected ? color : AppColors.borderGrey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(issue['icon'] as IconData, color: color, size: 26),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          issue['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Describe the Problem',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _problemCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "E.g. My motorcycle won't start and blablabla",
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addPhotos,
              icon: const Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.primary),
              label: Text(
                _photos.isEmpty ? 'Add Photos' : 'Add Photos (${_photos.length})',
                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.path),
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Your Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(hintText: 'Enter your location or use GPS'),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _fetchingLocation ? null : _useCurrentLocation,
              icon: _fetchingLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
              label: Text(
                _fetchingLocation ? 'Getting location…' : 'Use Current Location',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Urgency Level !!!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _UrgencyChip(
                label: 'Normal',
                color: AppColors.green,
                selected: _urgency == 'Normal',
                onTap: () => setState(() => _urgency = 'Normal'),
              ),
              const SizedBox(width: 10),
              _UrgencyChip(
                label: 'Urgent',
                color: AppColors.yellow,
                selected: _urgency == 'Urgent',
                onTap: () => setState(() => _urgency = 'Urgent'),
              ),
              const SizedBox(width: 10),
              _UrgencyChip(
                label: 'Emergency',
                color: AppColors.primary,
                selected: _urgency == 'Emergency',
                onTap: () => setState(() => _urgency = 'Emergency'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(14),
            color: AppColors.blue.withValues(alpha: 0.08),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.attach_money, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How pricing works', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.blue, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Upload your problem and mechanics will review it and send their quotes. '
                        'You\'ll see them under the notification bell, where you can compare '
                        'prices and choose the best mechanic for you.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _uploadRequest,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(_uploading ? 'Uploading…' : 'Upload'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: selected ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}