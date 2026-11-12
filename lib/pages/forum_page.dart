import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// v0.1: open the community forum in the system browser (no WordPress API keys in app).
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL is invalid.')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the forum.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Greyskull Nation Forum',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse and post in the community using your browser. '
              'This open-source app does not embed forum API secrets; account login happens on the website.',
            ),
            const SizedBox(height: 16),
            Text(
              'Forum: ${trainingState.forumUrl}',
              style: TextStyle(color: AppTheme.mutedText(context)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openUrl(context, trainingState.forumUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Forum'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openUrl(context, trainingState.forumLoginUrl),
              icon: const Icon(Icons.login),
              label: const Text('Forum Login / Register'),
            ),
            const SizedBox(height: 12),
            Text(
              'Optional display name and forum URLs are in Settings.',
              style:
                  TextStyle(fontSize: 13, color: AppTheme.mutedText(context)),
            ),
          ],
        );
      },
    );
  }
}
