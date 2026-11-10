import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  WebViewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    final url = trainingState.storeUrl;
    _controller ??= WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller!.loadRequest(Uri.parse(url));
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
        _initControllerIfNeeded();
        return Column(
          children: [
            ListTile(
              title: const Text('Greyskull Store'),
              subtitle: Text(trainingState.storeUrl),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openExternal(trainingState.storeUrl),
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
