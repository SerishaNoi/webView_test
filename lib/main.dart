import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_and_store_deploy/back_event_notifier.dart';
import 'package:webview_and_store_deploy/pull_to_refresh.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late WebViewController _controller;
  late DragGesturePullToRefresh dragGesturePullToRefresh;
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
    dragGesturePullToRefresh = DragGesturePullToRefresh();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      WebView.platform == SurfaceAndroidWebView();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() {
    dragGesturePullToRefresh.setHeight(MediaQuery.of(context).size.height);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBack(),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => dragGesturePullToRefresh.refresh(),
            child: Builder(
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    WebView(
                      gestureRecognizers: {Factory(() => dragGesturePullToRefresh)},
                      gestureNavigationEnabled: true,
                      onWebViewCreated: (controller) {
                        _controller = controller;
                        dragGesturePullToRefresh.setContext(context).setController(_controller);
                      },
                      initialUrl: 'https://sindbadcity.com/',
                      javascriptMode: JavascriptMode.unrestricted,
                      onProgress: (int progress) {
                        print('WebView is loading (progress : $progress%)');
                      },
                      onPageStarted: (String url) {
                        dragGesturePullToRefresh.started();
                        print('Page started loading: $url');
                      },
                      onPageFinished: (String url) {
                        dragGesturePullToRefresh.finished();
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
