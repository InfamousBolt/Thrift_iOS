import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Cart.dart';
import 'package:eshop_multivendor/Screen/Favorite.dart';
import 'package:eshop_multivendor/Screen/Search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'Color.dart';
import 'Constant.dart';
import 'Demo_Localization.dart';
import 'String.dart';

const String isLogin = appName + 'isLogin';

setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

back() {
  return const BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.grad1Color, colors.grad2Color],
        stops: [0, 1]),
  );
}

shadow() {
  return const BoxDecoration(
    boxShadow: [
      BoxShadow(color: Color(0x1a0400ff), offset: Offset(0, 0), blurRadius: 30)
    ],
  );
}

placeHolder(double height) {
  return const AssetImage(
    'assets/images/placeholder.png',
  );
}

erroWidget(double size) {
  return Image.asset(
    'assets/images/placeholder.png',
    height: size,
    width: size,
  );
}

errorWidget(double size) {
  return Icon(
    Icons.account_circle_outlined,
    size: size,
  );
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

getAppBar(
  String title,
  BuildContext context,
) {
  return AppBar(
    titleSpacing: 0,
    backgroundColor: Theme.of(context).colorScheme.white,
    leading: Builder(
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => Navigator.of(context).pop(),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.primary,
              ),
            ),
          ),
        );
      },
    ),
    title: Text(
      title,
      style:
          const TextStyle(color: colors.primary, fontWeight: FontWeight.normal),
    ),
    actions: <Widget>[
      IconButton(
          icon: SvgPicture.asset(
            imagePath + 'search.svg',
            height: 20,
            color: colors.primary,
          ),
          onPressed: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const Search(),
                ));
          }),
      title == getTranslated(context, 'FAVORITE')
          ? Container()
          : IconButton(
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
                  ),
                );
              },
            ),
      Selector<UserProvider, String>(
        builder: (context, data, child) {
          return IconButton(
            icon: Stack(
              children: [
                Center(
                    child: SvgPicture.asset(
                  imagePath + 'appbarCart.svg',
                  color: colors.primary,
                )),
                (data.isNotEmpty && data != '0')
                    ? Positioned(
                        bottom: 20,
                        right: 0,
                        child: Container(
                          //  height: 20,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: colors.primary),
                          child: Center(
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
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const Cart(
                    fromBottom: false,
                  ),
                ),
              );
            },
          );
        },
        selector: (_, homeProvider) => homeProvider.curCartCount,
      )
    ],
  );
}

getSimpleAppBar(
  String title,
  BuildContext context,
) {
  return AppBar(
    titleSpacing: 0,
    backgroundColor: Theme.of(context).colorScheme.white,
    leading: Builder(builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => Navigator.of(context).pop(),
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.primary,
            ),
          ),
        ),
      );
    }),
    title: Text(
      title,
      style:
          const TextStyle(color: colors.primary, fontWeight: FontWeight.normal),
    ),
  );
}

noIntImage() {
  return SvgPicture.asset(
    'assets/images/no_internet.svg',
    fit: BoxFit.contain,
  );
}

setSnackbar(String msg, BuildContext context) {
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

String imagePath = 'assets/images/';

noIntText(BuildContext context) {
  return Text(getTranslated(context, 'NO_INTERNET')!,
      style: Theme.of(context)
          .textTheme
          .headline5!
          .copyWith(color: colors.primary, fontWeight: FontWeight.normal));
}

noIntDec(BuildContext context) {
  return Container(
    padding:
        const EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
    child: Text(getTranslated(context, 'NO_INTERNET_DISC')!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headline6!.copyWith(
              color: Theme.of(context).colorScheme.lightBlack2,
              fontWeight: FontWeight.normal,
            )),
  );
}

Widget showCircularProgress(bool _isProgress, Color color) {
  if (_isProgress) {
    return Center(
        child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ));
  }
  return const SizedBox(
    height: 0.0,
    width: 0.0,
  );
}

imagePlaceHolder(double size, BuildContext context) {
  return SizedBox(
    height: size,
    width: size,
    child: Icon(
      Icons.account_circle,
      color: Theme.of(context).colorScheme.white,
      size: size,
    ),
  );
}

String? validateUserName(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  }
  if (value.length <= 1) {
    return msg2;
  }
  return null;
}

String? validateMob(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  }
  if (value.length < 6) {
    return msg2;
  }
  return null;
}

String? validateCountryCode(String value, String msg1, String msg2) {
  if (value.isEmpty) {
    return msg1;
  }
  if (value.isEmpty) {
    return msg2;
  }
  return null;
}

String? validatePass(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  } else if (value.length <= 5) {
    return msg2;
  } else {
    return null;
  }
}

String? validateAltMob(String value, String? msg) {
  if (value.isNotEmpty) if (value.length < 9) {
    return msg;
  }
  return null;
}

String? validateField(String value, String? msg) {
  if (value.isEmpty) {
    return msg;
  } else {
    return null;
  }
}

String? validatePincode(String value, String? msg1) {
  if (value.isEmpty) {
    return msg1;
  } else {
    return null;
  }
}

String? validateEmail(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  } else if (!RegExp(
          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
          r'*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+'
          r'[a-z0-9](?:[a-z0-9-]*[a-z0-9])?')
      .hasMatch(value)) {
    return msg2;
  } else {
    return null;
  }
}

Widget getProgress() {
  return const Center(child: CircularProgressIndicator());
}



Widget getNoItem(BuildContext context) {
  return Center(child: Text(getTranslated(context, 'noItem')!));
}

Widget shimmer(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.simmerBase,
      highlightColor: Theme.of(context).colorScheme.simmerHigh,
      child: SingleChildScrollView(
        child: Column(
          children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
              .map((_) => Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.0,
                          height: 80.0,
                          color: Theme.of(context).colorScheme.white,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: double.infinity,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: 100.0,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: 20.0,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    ),
  );
}

Widget singleItemSimmer(BuildContext context) {
  return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80.0,
                  height: 80.0,
                  color: Theme.of(context).colorScheme.white,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 18.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: double.infinity,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: 100.0,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: 20.0,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )));
}

simmerSingleProduct(BuildContext context) {
  return Container(
      //width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          color: Theme.of(context).colorScheme.white,
        ),
      ));
}

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LAGUAGE_CODE) ?? 'en';
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case 'en':
      return const Locale('en', 'US');
    case 'zh':
      return const Locale('zh', 'CN');
    case 'es':
      return const Locale('es', 'ES');
    case 'hi':
      return const Locale('hi', 'IN');
    case 'ar':
      return const Locale('ar', 'DZ');
    case 'ru':
      return const Locale('ru', 'RU');
    case 'ja':
      return const Locale('ja', 'JP');
    case 'de':
      return const Locale('de', 'DE');
    default:
      return const Locale('en', 'US');
  }
}

String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)!.translate(key);
}

String? getPriceFormat(BuildContext context, double price) {
  return NumberFormat.currency(
          locale: Platform.localeName,
          name: '$supportedLocale',
          symbol: '$CUR_CURRENCY')
      .format(price)
      .toString();
}

String getToken() {
  final claimSet = JwtClaim(
    issuer: 'eshop',
    maxAge: const Duration(minutes: 5),
    issuedAt: DateTime.now().toUtc(),
  );
  String token = issueJwtHS256(claimSet, jwtKey);
  return token;
}

Map<String, String> get headers => {
      'Authorization': 'Bearer ' + getToken(),
    };

dialogAnimate(BuildContext context, Widget dialge) {
  return showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(opacity: a1.value, child: dialge),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      // pageBuilder: null
      pageBuilder: (context, animation1, animation2) {
        return Container();
      } //as Widget Function(BuildContext, Animation<double>, Animation<double>)
      );
}

//for scroll on webview
final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
  Factory(() => EagerGestureRecognizer()),
};