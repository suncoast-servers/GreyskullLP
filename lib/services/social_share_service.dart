import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/training_state.dart';

typedef ShareHandler = Future<void> Function({
  required String text,
  String? subject,
  Rect? sharePositionOrigin,
  List<XFile>? files,
});

class SocialShareService {
  SocialShareService._();

  /// Injectable handler for unit and widget testing.
  @visibleForTesting
  static ShareHandler? shareHandler;

  /// Default brand hashtag and attribution.
  static const String defaultAttribution =
      'Tracked with the official Greyskull LP App (sanctioned by Johnny Pain).';
  static const String defaultHashtag = '#GreyskullLP #JohnnyPain';

  /// Formats a complete social share caption from a workout [HistoryEntry].
  static String formatWorkoutCaption({
    required HistoryEntry entry,
    String? customHashtag,
    String? userNote,
  }) {
    final buffer = StringBuffer();
    final tag = (customHashtag?.trim().isNotEmpty ?? false)
        ? customHashtag!.trim()
        : defaultHashtag;

    switch (entry.category) {
      case HistoryCategory.weight:
        buffer.writeln('Crushed my Greyskull LP workout! 💥');
        buffer.writeln();
        buffer.writeln('🏋️ Program: ${entry.title}');
        buffer.writeln('• Lifts: ${entry.details.replaceAll('\n', '\n• ')}');
        if (entry.weightVolume != null && entry.weightVolume! > 0) {
          buffer.writeln(
              '• Total Volume: ${entry.weightVolume!.toStringAsFixed(1)} lbs');
        }
        break;

      case HistoryCategory.daily:
        buffer.writeln('Logged my daily Greyskull LP work! 🦍');
        buffer.writeln();
        buffer.writeln('💪 Method: ${entry.title}');
        buffer.writeln('• Details: ${entry.details.replaceAll('\n', '\n• ')}');
        if (entry.pushUps != null && entry.pushUps! > 0) {
          buffer.writeln('• Push-ups: ${entry.pushUps}');
        }
        if (entry.chinUps != null && entry.chinUps! > 0) {
          buffer.writeln('• Chin-ups: ${entry.chinUps}');
        }
        break;

      case HistoryCategory.diet:
        buffer.writeln('Greyskull LP nutrition update! 🥩');
        buffer.writeln();
        buffer.writeln('🎯 ${entry.title}');
        buffer.writeln('• Details: ${entry.details.replaceAll('\n', '\n• ')}');
        if (entry.proteinGrams != null && entry.proteinGrams! > 0) {
          buffer.writeln('• Protein: ${entry.proteinGrams}g');
        }
        if (entry.calories != null && entry.calories! > 0) {
          buffer.writeln('• Energy: ${entry.calories} kcal');
        }
        break;
    }

    if (userNote != null && userNote.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💬 Note: ${userNote.trim()}');
    }

    buffer.writeln();
    buffer.writeln(defaultAttribution);
    buffer.writeln(tag);

    return buffer.toString().trim();
  }

  /// Triggers the native platform share sheet with text and optional media.
  static Future<void> shareWorkout({
    required BuildContext context,
    required HistoryEntry entry,
    XFile? photo,
    String? customNote,
    String? customHashtag,
  }) async {
    final caption = formatWorkoutCaption(
      entry: entry,
      customHashtag: customHashtag,
      userNote: customNote,
    );

    // Compute iPad/tablet anchor bounds so share sheet never crashes
    Rect? origin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {
      origin = null;
    }

    if (shareHandler != null) {
      await shareHandler!(
        text: caption,
        subject: 'My Greyskull LP Workout',
        sharePositionOrigin: origin,
        files: photo != null ? [photo] : null,
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: caption,
        subject: 'My Greyskull LP Workout',
        sharePositionOrigin: origin,
        files: photo != null ? [photo] : null,
      ),
    );
  }

  /// Tests (and headless runs) never pop the post-log sheet; tests can force
  /// it back on to exercise the flow.
  @visibleForTesting
  static bool? debugForceAutoPrompt;

  static bool get _autoPromptAllowed {
    if (debugForceAutoPrompt != null) return debugForceAutoPrompt!;
    if (kIsWeb) return true;
    try {
      return Platform.environment['FLUTTER_TEST'] != 'true';
    } catch (_) {
      return true;
    }
  }

  /// Shows the share sheet right after a workout/session is logged (#110).
  static void maybePromptAfterLog(BuildContext context, HistoryEntry entry) {
    if (!_autoPromptAllowed) return;
    if (!trainingState.socialSharePromptEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showShareModal(context: context, entry: entry);
    });
  }

  /// Opens an interactive pre-share review modal sheet.
  /// Allows the user to inspect/edit their caption and optionally attach a photo.
  static Future<void> showShareModal({
    required BuildContext context,
    required HistoryEntry entry,
    String? defaultHashtag,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return _SocialShareModalContent(
          entry: entry,
          defaultHashtag: defaultHashtag ?? defaultHashtag,
        );
      },
    );
  }
}

class _SocialShareModalContent extends StatefulWidget {
  const _SocialShareModalContent({
    required this.entry,
    this.defaultHashtag,
  });

  final HistoryEntry entry;
  final String? defaultHashtag;

  @override
  State<_SocialShareModalContent> createState() =>
      _SocialShareModalContentState();
}

class _SocialShareModalContentState extends State<_SocialShareModalContent> {
  late final TextEditingController _captionController;
  XFile? _attachedPhoto;
  bool _isPickingPhoto = false;
  final TextEditingController _locationController = TextEditingController();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final initialCaption = SocialShareService.formatWorkoutCaption(
      entry: widget.entry,
      customHashtag: widget.defaultHashtag,
    );
    _captionController = TextEditingController(text: initialCaption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _captionWithExtras {
    final buffer = StringBuffer(_captionController.text.trim());
    final location = _locationController.text.trim();
    if (location.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write('📍 $location');
    }
    return buffer.toString();
  }

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: _captionWithExtras));
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption copied')),
      );
    }
  }

  Future<void> _postToForum() async {
    await _copyCaption();
    final uri = Uri.tryParse(trainingState.forumUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickPhoto({ImageSource source = ImageSource.gallery}) async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo != null && mounted) {
        setState(() => _attachedPhoto = photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _handleShare() async {
    final caption = _captionWithExtras;
    if (caption.isEmpty) {
      return;
    }

    Navigator.of(context).pop();

    Rect? origin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {
      origin = null;
    }

    if (SocialShareService.shareHandler != null) {
      await SocialShareService.shareHandler!(
        text: caption,
        subject: 'My Greyskull LP Workout',
        sharePositionOrigin: origin,
        files: _attachedPhoto != null ? [_attachedPhoto!] : null,
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: caption,
        subject: 'My Greyskull LP Workout',
        sharePositionOrigin: origin,
        files: _attachedPhoto != null ? [_attachedPhoto!] : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Workout to Social',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Share your progress with your gym partners, team, or followers.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionController,
            maxLines: 6,
            minLines: 4,
            decoration: const InputDecoration(
              labelText: 'Workout Caption',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              hintText: 'e.g. Suncoast Barbell',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          if (_attachedPhoto != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: kIsWeb
                        ? const Icon(Icons.image, size: 40)
                        : Image.file(
                            File(_attachedPhoto!.path),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image, size: 40),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachedPhoto!.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Remove photo',
                    onPressed: () => setState(() => _attachedPhoto = null),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isPickingPhoto
                    ? null
                    : () => _pickPhoto(source: ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Selfie'),
              ),
              OutlinedButton.icon(
                onPressed: _isPickingPhoto ? null : _pickPhoto,
                icon: _isPickingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo, size: 18),
                label:
                    Text(_attachedPhoto == null ? 'Gallery' : 'Change photo'),
              ),
              OutlinedButton.icon(
                onPressed: _copyCaption,
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                label: Text(_copied ? 'Copied' : 'Copy caption'),
              ),
              OutlinedButton.icon(
                onPressed: _postToForum,
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: const Text('Forum'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _handleShare,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share to apps / save'),
          ),
        ],
      ),
    );
  }
}
