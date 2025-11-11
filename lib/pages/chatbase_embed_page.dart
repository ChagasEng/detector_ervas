import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ChatbaseEmbedPage extends StatefulWidget {
  const ChatbaseEmbedPage({super.key});

  @override
  State<ChatbaseEmbedPage> createState() => _ChatbaseEmbedPageState();
}

class _ChatbaseEmbedPageState extends State<ChatbaseEmbedPage> {
  late final WebViewController _controller;
  bool _loading = true;

  final String _iframeUrl =
      "https://www.chatbase.co/chatbot-iframe/RmehOVMMrwNwTufvX7lkO";

  @override
  void initState() {
    super.initState();

    // ✅ Corrige inicialização por plataforma
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(_iframeUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.agriculture_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Plant Scan Assistente 🤖",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 70),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                color: const Color(0xFFF8FFF9),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ),

          // 🔄 Loader elegante
          if (_loading)
            Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 3.5,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Carregando o assistente agrícola...",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
