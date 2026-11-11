import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountabilityPostSheet extends StatefulWidget {
  final AccountabilityDraft draft;

  const AccountabilityPostSheet({super.key, required this.draft});

  static Future<void> show(
    BuildContext context, {
    required AccountabilityDraft draft,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AccountabilityPostSheet(draft: draft),
      ),
    );
  }

  @override
  State<AccountabilityPostSheet> createState() =>
      _AccountabilityPostSheetState();
}

class _AccountabilityPostSheetState extends State<AccountabilityPostSheet> {
  late final TextEditingController _contentController;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.draft.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _contentController.text));
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accountability post draft copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openForum() async {
    await _copyToClipboard();
    final url = trainingState.forumUrl;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignedIn = trainingState.forumSignedIn;
    final displayName = trainingState.forumDisplayName.isEmpty
        ? 'Lifter'
        : trainingState.forumDisplayName;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Category
          Row(
            children: [
              Icon(
                widget.draft.category == 'weight'
                    ? Icons.fitness_center
                    : (widget.draft.category == 'daily'
                        ? Icons.accessibility_new
                        : Icons.calendar_today),
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forum Accountability Post',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Auth status guidance card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSignedIn
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSignedIn
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSignedIn ? Icons.check_circle : Icons.info_outline,
                  color: isSignedIn ? Colors.green : Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSignedIn
                            ? 'Ready for forum submission ($displayName)'
                            : 'REST API credentials pending founder setup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSignedIn
                              ? Colors.green.shade800
                              : Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSignedIn
                            ? 'Draft copied to clipboard. Ready to paste into the discussion thread.'
                            : 'Draft is copied to your clipboard. Paste it directly into the Greyskull Nation forum thread.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Formatted draft preview / editor
          TextField(
            controller: _contentController,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Post Body (BBCode / Markdown)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Zero private data included. Edit before posting.',
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 16,
                  ),
                  label: Text(_copied ? 'Copied' : 'Copy Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openForum,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open Forum'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
