import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WebView Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController _controller;
  bool isLoading = true;

  void startTimer() {
    Timer.periodic(const Duration(seconds: 3), (t) {
      setState(() {
        isLoading = false;
      });
      t.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform == SurfaceAndroidWebView();
    }
    // if (Platform.isIOS){
    //   WebView.platform ==
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return _controller.reload();
        },
        child: Stack(
          children: [
            WebView(
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              initialUrl: 'https://sindbadcity.com/',
              javascriptMode: JavascriptMode.unrestricted,
              onProgress: (int progress) {
                print('WebView is loading (progress : $progress%)');
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
                startTimer();
              },
            ),
            isLoading
                ? Center(
                    child: Expanded(
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: const Image(
                          image: AssetImage(
                            'lib/assets/assetGif.gif',
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  void refreshWebView() {
    _controller.reload();
  }
}
