import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_and_store_deploy/back_event_notifier.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BackEventNotifier(),
      child: const MyApp(),
    ),
  );
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
  final GlobalKey _globalKey = GlobalKey();

  void startTimer() {
    Timer.periodic(const Duration(seconds: 1), (t) {
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBack(),
      child: Scaffold(
        body: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                WebView(
                  gestureRecognizers: Set()
                    ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()
                      ..onDown = (DragDownDetails dragDownDetails) {
                        _controller.getScrollY().then((value) {
                          if (value == 0 && dragDownDetails.globalPosition.direction < 1) {
                            _controller.reload();
                          }
                        });
                      })),
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
                        child: Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Image.asset(
                              'lib/assets/assetGif.gif',
                            ),
                          ),
                        ),
                      )
                    : const SizedBox()
              ],
            ),
          ),
        ),
      ),
      // ),
    );
  }

  Future<bool> _onBack() async {
    var value = await _controller.canGoBack();

    if (value) {
      _controller.goBack();

      return false;
    } else {
      late BackEventNotifier notifier;
      await showDialog(
        context: _globalKey.currentState!.context,
        builder: (context) => Consumer(
          builder: (context, BackEventNotifier event, child) {
            notifier = event;
            return AlertDialog(
              title: const Text('Confirmation ', style: TextStyle(color: Colors.purple)),
              content: const Text('Do you want exit app ? '),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    event.add(false);
                  },

                  child: const Text("No"), // No
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    event.add(true);
                  },
                  child: const Text("Yes"), // Yes
                ),
              ],
            );
          },
        ),
      );

      print("_notifier.isBack ${notifier.isBack}");
      return notifier.isBack;
    }
  }
}
