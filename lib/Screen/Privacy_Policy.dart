import 'dart:async';
import 'dart:convert';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;

  const PrivacyPolicy({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? privacy;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  // final flutterWebViewPlugin = FlutterWebviewPlugin();
  // late StreamSubscription<WebViewStateChanged> _onStateChanged;
  //InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();

    getSetting();
    // flutterWebViewPlugin.close();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));

    // _onStateChanged =
    //     flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
    //   if (state.type == WebViewState.abortLoad) {
    //     _launchSocialNativeLink(state.url);
    //   }
    // });
  }


  @override
  void dispose() {
    buttonController!.dispose();
    // _onStateChanged.cancel();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            key: _scaffoldKey,
            appBar: getSimpleAppBar(widget.title!, context),
            body: getProgress(),
          )
        : privacy != ''
            ? Scaffold(
                key: _scaffoldKey,
                appBar: getSimpleAppBar(widget.title!, context),
                body: WebView(
                    gestureRecognizers: gestureRecognizers,
                    backgroundColor: Theme.of(context).colorScheme.lightWhite,
                    zoomEnabled: true,
                    javascriptMode: JavascriptMode.unrestricted,
                    initialUrl: 'about:blank',
                    onWebViewCreated: (WebViewController webViewController) {
                      webViewController.loadHtmlString(privacy!);
                    }))
            : Scaffold(
                key: _scaffoldKey,
                appBar: getSimpleAppBar(widget.title!, context),
                body: _isNetworkAvail ? Container() : noInternet(context),
              );
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String? type;
        if (widget.title == getTranslated(context, 'PRIVACY')) {
          type = PRIVACY_POLLICY;
        } else if (widget.title == getTranslated(context, 'TERM')) {
          type = TERM_COND;
        } else if (widget.title == getTranslated(context, 'ABOUT_LBL')) {
          type = ABOUT_US;
        } else if (widget.title == getTranslated(context, 'CONTACT_LBL')) {
          type = CONTACT_US;
        } else if (widget.title ==
            getTranslated(context, 'SHIPPING_POLICY_LBL')) {
          type = shippingPolicy;
        } else if (widget.title ==
            getTranslated(context, 'RETURN_POLICY_LBL')) {
          type = returnPolicy;
        }

        var parameter = {TYPE: type};
        Response response =
            await post(getSettingApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));


        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            privacy = getdata['data'][type][0].toString();

          } else {
            setSnackbar(msg!);
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        _isLoading = false;
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNetworkAvail = false;
        });
      }
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }
}
