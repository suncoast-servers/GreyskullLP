import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// v0.1: open the official storefront in the system browser (no embedded WebView).
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  static const String _defaultUrl = 'https://store.greyskullnation.com/';

  Future<void> _openStore(BuildContext context) async {
    final url = trainingState.storeUrl.trim().isEmpty
        ? _defaultUrl
        : trainingState.storeUrl;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store URL is invalid.')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the store.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final url = trainingState.storeUrl.trim().isEmpty
            ? _defaultUrl
            : trainingState.storeUrl;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Greyskull Store',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shop books, apparel, and coaching on the official Greyskull Nation storefront. '
              'Opens in your browser with no in-app purchase or API keys required.',
            ),
            const SizedBox(height: 16),
            Text('URL: $url', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openStore(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Greyskull Store'),
            ),
            const SizedBox(height: 12),
            Text(
              'Change the store URL in Settings if needed.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }
}
