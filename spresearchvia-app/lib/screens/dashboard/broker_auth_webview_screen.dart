import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/snackbar.service.dart';

class BrokerAuthWebviewScreen extends StatefulWidget {
  final String authUrl;
  const BrokerAuthWebviewScreen({super.key, required this.authUrl});

  @override
  State<BrokerAuthWebviewScreen> createState() => _BrokerAuthWebviewScreenState();
}

class _BrokerAuthWebviewScreenState extends State<BrokerAuthWebviewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkCallback(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkCallback(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkCallback(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  bool _checkCallback(String url) {
    if (url.startsWith('researchvia://broker-callback')) {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'];
      final error = uri.queryParameters['error'];

      if (status == 'success') {
        SnackbarService.showSuccess('Broker authorization completed successfully!');
        Get.back(result: true);
      } else {
        SnackbarService.showError(error ?? 'Authorization failed.');
        Get.back(result: false);
      }
      return true;
    }
    if (url.contains('/callback/success')) {
      SnackbarService.showSuccess('Broker authorization completed successfully!');
      Get.back(result: true);
      return true;
    } else if (url.contains('/callback/failure')) {
      final uri = Uri.parse(url);
      final error = uri.queryParameters['error'];
      SnackbarService.showError(error ?? 'Authorization failed.');
      Get.back(result: false);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Broker Authorization',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
