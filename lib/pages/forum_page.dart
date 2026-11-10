import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  WebViewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    if (_controller != null) {
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller!.loadRequest(Uri.parse(trainingState.forumUrl));
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        if (!trainingState.forumSignedIn) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Forum Sign-In Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in from Settings, or open the WordPress login page below. '
                'Once credentials/API details are provided by the owner, this can be upgraded to proper auth sync.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openExternal(trainingState.forumLoginUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Forum Login in Browser'),
              ),
            ],
          );
        }

        _initControllerIfNeeded();
        return Column(
          children: [
            ListTile(
              title: Text(
                trainingState.forumDisplayName.isEmpty
                    ? 'Signed in'
                    : 'Signed in as ${trainingState.forumDisplayName}',
              ),
              subtitle: Text(trainingState.forumUrl),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openExternal(trainingState.forumUrl),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: WebViewWidget(controller: _controller!)),
          ],
        );
      },
    );
  }
}
