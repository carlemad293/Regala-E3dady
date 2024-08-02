import 'dart:html' as html; // Import dart:html for browser-specific functionality

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const WebViewApp());
}

class WebViewApp extends StatelessWidget {
  const WebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force the orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();

    // Check if running on web platform
    if (kIsWeb) {
      // Open the URL in a new tab
      html.window.open(
          'https://docs.google.com/spreadsheets/d/1lJK56ELlOpg9QJV8XvAszuz98JnEGOCVCn3JgmIqQxQ/edit?usp=sharing',
          '_blank');
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {
              // Inject JavaScript to hide the title bar and back button as soon as the page starts loading
              controller.runJavaScript('''
                document.addEventListener('DOMContentLoaded', function() {
                  // Hide the title bar and back button
                  document.querySelector('div.docs-titlebar').style.display='none';
                  document.querySelector('div#docs-header').style.display='none';
                  
                  // Make the spreadsheet read-only
                  let observer = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                      if (mutation.target.contentEditable === "true") {
                        mutation.target.contentEditable = "false";
                      }
                    });
                  });

                  let config = { attributes: true, childList: true, subtree: true };
                  observer.observe(document.body, config);
                });
              ''');
            },
            onPageFinished: (String url) {
              // Ensure elements are hidden and the spreadsheet is read-only after the page finishes loading
              controller.runJavaScript('''
                document.querySelector('div.docs-titlebar').style.display='none';
                document.querySelector('div#docs-header').style.display='none';
                document.querySelectorAll('[contenteditable]').forEach((el) => el.setAttribute('contenteditable', 'false'));
              ''');
            },
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              // Prevent navigation to other URLs
              if (!request.url.contains('https://docs.google.com/spreadsheets/')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(
          Uri.parse(
              'https://docs.google.com/spreadsheets/d/1lJK56ELlOpg9QJV8XvAszuz98JnEGOCVCn3JgmIqQxQ/edit?usp=sharing'),
        );
    }
  }

  @override
  void dispose() {
    // Revert the orientation to portrait when this screen is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If running on web platform, return an empty container as the URL is opened in a new tab
    if (kIsWeb) {
      return Container();
    }

    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
