import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PicaOSAuthWebview extends StatefulWidget {
  const PicaOSAuthWebview({
    required this.previewUrl,
    required this.onAuthSuccess,
    this.isTabletView = false,
    super.key,
    required this.onClose,
  });

  final String previewUrl;
  final bool isTabletView;
  final void Function(String) onAuthSuccess;
  final VoidCallback onClose;

  @override
  State<PicaOSAuthWebview> createState() => _PicaOSAuthWebviewState();
}

class _PicaOSAuthWebviewState extends State<PicaOSAuthWebview> {
  late final String url;
  InAppWebViewController? webViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: 'camera; geolocation; microphone',
    iframeSandbox: {
      Sandbox.ALLOW_SAME_ORIGIN,
      Sandbox.ALLOW_SCRIPTS,
      Sandbox.ALLOW_FORMS,
      Sandbox.ALLOW_POPUPS,
    },
    javaScriptEnabled: true,
  );

  @override
  void initState() {
    super.initState();
    url = widget.previewUrl;
  }

  // Method to close the auth dialog
  void closeAuthDialog() {
    debugPrint("Closing auth dialog from Flutter");
    webViewController?.evaluateJavascript(source: """
      try {
        if (window.closeAuthModal && typeof window.closeAuthModal === 'function') {
          window.closeAuthModal();
        }
        true;
      } catch (e) {
        console.error("Error closing dialog:", e);
        false;
      }
    """);
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: settings,
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onWebViewCreated: (controller) {
        webViewController = controller;
        debugPrint("WebView created");
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        print('url host = ${url?.host}');
        if (url != null) {
          if (url.host.contains('other')) {
            Navigator.of(context).pop();
          }
        }
      },
      onLoadStart: (controller, url) {
        debugPrint("WebView starting to load: $url");

        // Check if URL indicates auth is closed
        if (url.toString().contains("/auth-closed")) {
          debugPrint("Auth closed URL detected, closing WebView");
          widget.onClose();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
        // Check for auth success
        else if (url.toString().contains("/auth-success")) {
          debugPrint("Auth success URL detected");
          // You could extract data from the URL or page if needed
          webViewController?.evaluateJavascript(source: """
            document.body.innerText
          """).then((data) {
            widget.onAuthSuccess(data ?? "{}");
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
        // Check for auth error
        else if (url.toString().contains("/auth-error")) {
          debugPrint("Auth error URL detected, closing WebView");
          widget.onClose();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("WebView Console: ${consoleMessage.message}");
      },
      onLoadStop: (controller, url) async {
        debugPrint("WebView loaded: $url");

        // Set up styling
        await controller.evaluateJavascript(source: """
          document.body.style.backgroundColor = 'white';
          document.documentElement.style.backgroundColor = 'white';
          document.documentElement.style.width = "100%";
          document.body.style.width = "100%";
          document.body.style.margin = "0";
          document.body.style.padding = "0";
          
          console.log("Page fully loaded");
        """);
      },
    );
  }
}
