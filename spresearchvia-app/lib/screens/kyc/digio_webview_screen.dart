import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DigioWebViewScreen extends StatefulWidget {
  final String docId;
  final String identifier;
  final String token;
  final String environment;

  const DigioWebViewScreen({
    super.key,
    required this.docId,
    required this.identifier,
    required this.token,
    required this.environment,
  });

  @override
  State<DigioWebViewScreen> createState() => _DigioWebViewScreenState();
}

class _DigioWebViewScreenState extends State<DigioWebViewScreen> {
  WebViewController? _controller;
  static const String _redirectionUrlDomain = "www.digio.in"; // Standard redirect for Digio

  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _checkConnectivityAndLoad();
  }

  Future<void> _checkConnectivityAndLoad() async {
    setState(() {
      _hasError = false;
    });
    
    try {
      // Check for actual internet connection (IP reachability)
      final result = await InternetAddress.lookup('8.8.8.8');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        initializeWebView();
      } else {
        throw const SocketException("No Internet");
      }
    } catch (e) {
      debugPrint("Connectivity Check Failed: $e");
      // Fallback: If connectivity check fails on emulator due to DNS but internet works via proxy, try loading anyway.
      // Or show error. Here we show error but allow retry.
      if (e.toString().contains("SocketException")) {
         // Attempt to load anyway if it's just a DNS lookup failure on 8.8.8.8?
         // No, better to show error.
      }
      setState(() {
        _hasError = true;
        _errorMessage = 'No Internet Connection.\nEmulator requires a Cold Boot.';
      });
    }
  }

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  void initializeWebView() {
    setState(() {
      _hasError = false;
    });

    final url = getUrl();
    print("----------------------------------------------------------------");
    print("DIGIO WEBVIEW URL: $url");
    print("----------------------------------------------------------------");
    debugPrint("DigioWebView URL: $url");
    
    // Modern user agent to prevent bot detection
    const String userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            debugPrint("Navigating to: ${request.url}");
            final uri = Uri.parse(request.url);
            
            // CRITICAL: Only intercept if it looks like a completion redirect.
            // Digio returns status, digio_doc_id, message, txn_id in the redirect.
            if (uri.host.contains(_redirectionUrlDomain) && 
                (uri.queryParameters.containsKey('status') || uri.queryParameters.containsKey('digio_doc_id'))) { 
              parseResult(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.errorCode} - ${error.description}");
            if (error.errorCode == -2 || error.description.contains("NAME_NOT_RESOLVED")) { 
               setState(() {
                 _hasError = true;
                 _errorMessage = "Emulator Network Error (DNS).\n\nFIX:\n1. Close Emulator\n2. Device Manager -> Wipe Data\n3. Cold Boot";
               });
            } else if (error.errorCode == -6 || error.description.contains("CONNECTION_REFUSED")) {
               setState(() {
                 _hasError = true;
                 _errorMessage = "Connection Refused.\nServer might be down or blocked.";
               });
            }
          },
        ),
      )
      ..clearCache() // Ensure clean slate
      ..clearLocalStorage() 
      ..loadRequest(Uri.parse(url));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
  }

  String getUrl() {
    final baseUrl = widget.environment.toLowerCase() == "production"
        ? "https://app.digio.in"
        : "https://ext.digio.in";
    final txnId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // RESTORE ENCODING: Android WebView networking stack can be strict about special chars in path.
    // We encode it to ensure '@' becomes '%40'.
    final safeIdentifier = Uri.encodeComponent(widget.identifier);
    
    // Construct the base URL string carefully with the hash
    final url = StringBuffer(
        "$baseUrl/#/gateway/login/${widget.docId}/$txnId/$safeIdentifier");

    final theme = {
      "PRIMARY_COLOR": "#11416B", 
      "SECONDARY_COLOR": "#141414",
      "FONT_FAMILY": "Poppins",
    };

    final params = {
      "logo": "https://www.digio.in/images/digio_blue.png", 
      "token_id": widget.token,
      "theme": jsonEncode(theme),
      "redirect_url": "https://$_redirectionUrlDomain"
    };

    bool first = true;
    for (var entry in params.entries) {
      url.write(first ? '?' : '&');
      first = false;
      url.write('${entry.key}=${Uri.encodeQueryComponent(entry.value)}');
    }

    return url.toString();
  }

  void parseResult(Uri uri) {
    final status = uri.queryParameters["status"];
    final digioDocId = uri.queryParameters["digio_doc_id"];
    final message = uri.queryParameters["message"];

    debugPrint("DigioResponse: status=$status, docId=$digioDocId, message=$message");

    // Return the result string to be parsed by the caller, or handled here
    Map<String, String> result = {
      "status": status ?? "unknown",
      "docId": digioDocId ?? "",
      "message": message ?? ""
    };
    Navigator.pop(context, result); 
  } 

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Connection Failed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            // Show the URL for debugging
            SelectableText(
              getUrl(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkConnectivityAndLoad,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry Connection"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text("Digio Verification")),
        body: _buildErrorView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Digio Verification")),
      body: SafeArea(
        bottom: true,
        child: _controller == null 
            ? const Center(child: CircularProgressIndicator()) 
            : WebViewWidget(controller: _controller!),
      ),
    );
  }
}
