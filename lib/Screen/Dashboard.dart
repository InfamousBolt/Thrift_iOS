import 'dart:async';
import 'dart:convert';

import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/PushNotificationService.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Favorite.dart';
import 'package:eshop_multivendor/Screen/Login.dart';
import 'package:eshop_multivendor/Screen/MyProfile.dart';
import 'package:eshop_multivendor/Screen/Product_Detail.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'All_Category.dart';
import 'Cart.dart';
import 'HomePage.dart';
import 'NotificationLIst.dart';
import 'Sale.dart';
import 'Search.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Dashboard> with TickerProviderStateMixin {
  int _selBottom = 0;
  late TabController _tabController;
  bool _isNetworkAvail = true;

  late StreamSubscription streamSubscription;
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.initState();
    initDynamicLinks();
    _tabController = TabController(
      length: 5,
      vsync: this,
    );

    final pushNotificationService = PushNotificationService(
        context: context, tabController: _tabController);
    pushNotificationService.initialise();

    _tabController.addListener(
      () {
        Future.delayed(const Duration(seconds: 0)).then(
          (value) {
          },
        );

        setState(
          () {
            _selBottom = _tabController.index;
          },
        );
      },
    );
  }

  void initDynamicLinks() async {
    streamSubscription = FirebaseDynamicLinks.instance.onLink.listen((event) {
      final Uri? deepLink = event.link;
      if (deepLink != null) {
        if (deepLink.queryParameters.isNotEmpty) {
          int index = int.parse(deepLink.queryParameters['index']!);

          int secPos = int.parse(deepLink.queryParameters['secPos']!);

          String? id = deepLink.queryParameters['id'];

          String? list = deepLink.queryParameters['list'];

          getProduct(id!, index, secPos, list == 'true' ? true : false);
        }
      }
    });

   /* FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.length > 0) {
          int index = int.parse(deepLink.queryParameters['index']!);

          int secPos = int.parse(deepLink.queryParameters['secPos']!);

          String? id = deepLink.queryParameters['id'];

          String? list = deepLink.queryParameters['list'];

          getProduct(id!, index, secPos, list == "true" ? true : false);
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
    });
*/
  /*  final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.queryParameters.length > 0) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        // String list = deepLink.queryParameters['list'];

        getProduct(id!, index, secPos, true);
      }
    }*/
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: id,
        };

        // if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;
        Response response =
            await post(getProductApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String msg = getdata['message'];
        if (!error) {
          var data = getdata['data'];

          List<Product> items = [];

          items =
              (data as List).map((data) => Product.fromJson(data)).toList();

          Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) => ProductDetail(
                    index: list ? int.parse(id) : index,
                    model: list
                        ? items[0]
                        : sectionList[secPos].productList![index],
                    secPos: secPos,
                    list: list,
                  )));
        } else {
          if (msg != 'Products Not Found !') setSnackbar(msg, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        appBar: _getAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: const [
            HomePage(),
            AllCategory(),
            Sale(),
            Cart(
              fromBottom: true,
            ),
            MyProfile(),
          ],
        ),
        //fragments[_selBottom],
        bottomNavigationBar: _getBottomBar(),
      ),
    );
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1) {
      title = getTranslated(context, 'CATEGORY');
    } else if (_selBottom == 2) {
      title = getTranslated(context, 'OFFER');
    } else if (_selBottom == 3) {
      title = getTranslated(context, 'MYBAG');
    } else if (_selBottom == 4) {
      title = getTranslated(context, 'PROFILE');
    }

    return AppBar(
      centerTitle: _selBottom == 0 ? true : false,
      title: _selBottom == 0
          ? Image.asset(
              'assets/images/thrift-logo-for-top-new.png',
        height: 50,
            )
          : Text(
              title!,
              style: const TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.normal,
              ),
            ),

      leading: _selBottom == 0
          ? InkWell(
              child: Center(
                  child: SvgPicture.asset(
                imagePath + 'search.svg',
                height: 20,
                color: colors.primary,
              )),
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Search(),
                    ));
              },
            )
          : null,
      actions: <Widget>[
        IconButton(
          icon: SvgPicture.asset(
            imagePath + 'desel_notification.svg',
            color: colors.primary,
          ),
          onPressed: () {

            CUR_USERID != null
                ? Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const NotificationList(),
                    )).then((value) {
              if (value != null && value) {
                _tabController.animateTo(1);
              }
            })
                : Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Login(),
                    ));
          },
        ),
        IconButton(
          padding: const EdgeInsets.all(0),
          icon: SvgPicture.asset(
            imagePath + 'desel_fav.svg',
            color: colors.primary,
          ),
          onPressed: () {
          Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Favorite(),
                    ));
          },
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.white,
    );
  }

  getTabItem(String enabledImage, String disabledImage, int selectedIndex) {
    return
      Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _selBottom == selectedIndex ? 1 : 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(5.0)),
            width: _selBottom == selectedIndex ? 40 : 0,
            height: _selBottom == selectedIndex ? 40 : 0,
          ),
        ),
        _selBottom == selectedIndex
            ? SvgPicture.asset(
                imagePath + disabledImage,
                color: colors.primary,
              )
            : SvgPicture.asset(
                imagePath + disabledImage,
                color: colors.primary,
              ),
      ],
    );
  }

  Widget _getBottomBar() {
    return Material(
        color: Theme.of(context).colorScheme.white,
        child: Container(
          height: kBottomNavigationBarHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.black26, blurRadius: 10)
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: getTabItem('sel_home.svg', 'desel_home.svg', 0),
              ),
              Tab(
                child: getTabItem('category01.svg', 'category.svg', 1),
              ),
              Tab(
                child: getTabItem('sale02.svg', 'sale.svg', 2),
              ),
              Tab(
                child:
                  Selector<UserProvider, String>(
                    builder: (context, data, child) {
                      return Container(
                        color: Colors.transparent,
                        height: 40,
                        width: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: _selBottom == 3 ? 1 : 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(5.0)),
                                width: _selBottom == 3 ? 40 : 0,
                                height: _selBottom == 3 ? 40 : 0,
                              ),
                            ),
                            _selBottom == 3
                                ? SvgPicture.asset(
                              imagePath + 'cart01.svg',
                              color: colors.primary,
                            )
                                : SvgPicture.asset(
                              imagePath + 'cart.svg',
                              color: colors.primary,
                            ),
                            (data.isNotEmpty && data != '0' )
                                ? Positioned.directional(
                             top:3,
                              textDirection: Directionality.of(context),
                              end: 3,
                              child: Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary),
                                child:  Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(
                                      data,
                                      style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: colors.whiteTemp),
                                    ),
                                  ),
                                ),
                              ),
                            )
                                : Container()
                          ],
                        ),
                      );
                    },
                    selector: (_, homeProvider) => homeProvider.curCartCount, )
              ),
              Tab(
                child: getTabItem('profile01.svg', 'profile.svg', 4),
              ),
            ],
            indicatorColor: Colors.transparent,
            labelColor: colors.primary,
            labelStyle: const TextStyle(fontSize: 12),
          ),
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
