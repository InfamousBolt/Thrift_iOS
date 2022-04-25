import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eshop_multivendor/Provider/FavoriteProvider.dart';
import 'package:eshop_multivendor/Screen/PromoCode.dart';
import 'package:mime/mime.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Customer_Support.dart';
import 'package:eshop_multivendor/Screen/MyTransactions.dart';
import 'package:eshop_multivendor/Screen/ReferEarn.dart';
import 'package:eshop_multivendor/Screen/SendOtp.dart';
import 'package:eshop_multivendor/Screen/Setting.dart';
import 'package:eshop_multivendor/Screen/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Constant.dart';
import '../Provider/Theme.dart';
import '../main.dart';
import 'Faqs.dart';
import 'Manage_Address.dart';
import 'MyOrder.dart';
import 'My_Wallet.dart';
import 'Privacy_Policy.dart';
import 'package:http_parser/http_parser.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProfile();
}

class StateProfile extends State<MyProfile> with TickerProviderStateMixin {
  //String? profile, email;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final InAppReview _inAppReview = InAppReview.instance;
  var isDarkTheme;
  bool isDark = false;
  late ThemeNotifier themeNotifier;
  List<String> langCode = ['en', 'zh', 'es', 'hi', 'ar', 'ru', 'ja', 'de'];
  List<String?> themeList = [];
  List<String?> languageList = [];
  int? selectLan, curTheme;
  TextEditingController? curPassC, newPassC, confPassC;
  String? curPass, newPass, confPass, mobile;

  final GlobalKey<FormState> _changePwdKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();
  final confirmpassController = TextEditingController();
  final newpassController = TextEditingController();
  final passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String? currentPwd, newPwd, confirmPwd;
  FocusNode confirmPwdFocus = FocusNode();

  bool _isNetworkAvail = true;

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      languageList = [
        getTranslated(context, 'ENGLISH_LAN'),
        getTranslated(context, 'CHINESE_LAN'),
        getTranslated(context, 'SPANISH_LAN'),
        getTranslated(context, 'HINDI_LAN'),
        getTranslated(context, 'ARABIC_LAN'),
        getTranslated(context, 'RUSSIAN_LAN'),
        getTranslated(context, 'JAPANISE_LAN'),
        getTranslated(context, 'GERMAN_LAN')
      ];

      themeList = [
        getTranslated(context, 'SYSTEM_DEFAULT'),
        getTranslated(context, 'LIGHT_THEME'),
        getTranslated(context, 'DARK_THEME')
      ];

      _getSaved();
    });

    super.initState();
  }

  _getSaved() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? get = prefs.getString(APP_THEME);

    curTheme = themeList.indexOf(get == '' || get == DEFAULT_SYSTEM
        ? getTranslated(context, 'SYSTEM_DEFAULT')
        : get == LIGHT
            ? getTranslated(context, 'LIGHT_THEME')
            : getTranslated(context, 'DARK_THEME'));

    String getlng = await settingsProvider.getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? 'en' : getlng);

    if (mounted) setState(() {});
  }

  _getHeader() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10.0, top: 10),
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: 10.0,
          ),
          child: Row(
            children: [
              Selector<UserProvider, String>(
                  selector: (_, provider) => provider.profilePic,
                  builder: (context, profileImage, child) {
                    return getUserImage(
                        profileImage, openChangeUserDetailsBottomSheet);
                  }),
              /*         Container(
                margin: EdgeInsetsDirectional.only(end: 20),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 1.0, color: Theme.of(context).colorScheme.white)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        return userProvider.profilePic != ''
                            ? new FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(userProvider.profilePic),
                          height: 64.0,
                          width: 64.0,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(64),
                          placeholder: placeHolder(64),
                        )
                            : imagePlaceHolder(62);
                      }),
                ),
              ),*/
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.curUserName,
                      builder: (context, userName, child) {
                        nameController = TextEditingController(text: userName);
                        return Text(
                          userName == ''
                              ? getTranslated(context, 'GUEST')!
                              : userName,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                        );
                      }),
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.mob,
                      builder: (context, userMobile, child) {
                        return userMobile != ''
                            ? Text(
                                userMobile,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              )
                            : Container(
                                height: 0,
                              );
                      }),
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.email,
                      builder: (context, userEmail, child) {
                        emailController =
                            TextEditingController(text: userEmail);
                        return userEmail != ''
                            ? Text(
                                userEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              )
                            : Container(
                                height: 0,
                              );
                      }),

                  /* Consumer<UserProvider>(builder: (context, userProvider, _) {

                    return (userProvider.mob != "")
                        ? Text(
                            userProvider.mob,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(color: Theme.of(context).colorScheme.fontColor),
                          )
                        : Container(
                            height: 0,
                          );
                  }),*/
                  Consumer<UserProvider>(builder: (context, userProvider, _) {
                    return userProvider.curUserName == ''
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(top: 7),
                            child: InkWell(
                              child: Text(
                                  getTranslated(context, 'LOGIN_REGISTER_LBL')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: colors.primary,
                                        decoration: TextDecoration.underline,
                                      )),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const Login(),
                                    ));
                              },
                            ))
                        : Container();
                  }),
                ],
              ),
            ],
          ),
        ));
  }

  List<Widget> getLngList(BuildContext ctx, StateSetter setModalState) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    });
                  }
                  setModalState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? colors.primary
                                    : Theme.of(context).colorScheme.white,
                                border: Border.all(color: colors.grad2Color)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 15.0,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                languageList[index]!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack),
                              ))
                        ],
                      ),
                      // index == languageList.length - 1
                      //     ? Container(
                      //         margin: EdgeInsetsDirectional.only(
                      //           bottom: 10,
                      //         ),
                      //       )
                      //     : Divider(
                      //         color: Theme.of(context).colorScheme.lightBlack,
                      //       ),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale _locale = await setLocale(language);

    MyApp.setLocale(ctx, _locale);
  }

  Future<void> setUpdateUser(String userID,
      [oldPwd, newPwd, username, userEmail]) async {
    var apiBaseHelper = ApiBaseHelper();
    var data = {USER_ID: userID};
    if ((oldPwd != '') && (newPwd != '')) {
      data[OLDPASS] = oldPwd;
      data[NEWPASS] = newPwd;
    } else if ((username != '') && (userEmail != '')) {
      data[USERNAME] = username;
      data[EMAIL] = userEmail;
    }

    final result = await apiBaseHelper.postAPICall(getUpdateUserApi, data);

    bool error = result['error'];
    String? msg = result['message'];

    Navigator.of(context).pop();
    if (!error) {
      var settingProvider =
          Provider.of<SettingProvider>(context, listen: false);
      var userProvider = Provider.of<UserProvider>(context, listen: false);

      if ((username != '') && (userEmail != '')) {
        settingProvider.setPrefrence(USERNAME, username);
        userProvider.setName(username);
        settingProvider.setPrefrence(EMAIL, userEmail);
        userProvider.setEmail(userEmail);
      }

      setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!);
    } else {
      setSnackbar(msg!);
    }
  }

/*  Future<void> setUpdateUser() async {
    var data = {USER_ID: CUR_USERID, OLDPASS: curPass, NEWPASS: newPass};

    Response response =
        await post(getUpdateUserApi, body: data, headers: headers)
            .timeout(Duration(seconds: timeOut));
    if (response.statusCode == 200) {
      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg = getdata["message"];

      if (!error) {
        setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!);
      } else {
        setSnackbar(msg!);
      }
    }
  }*/

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  _getDrawer() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MY_ORDERS_LBL')!,
                'assets/images/pro_myorder.svg'),

        // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MANAGE_ADD_LBL')!,
                'assets/images/pro_address.svg'),

        //CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MYWALLET')!,
                'assets/images/pro_wh.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'YOUR_PROM_CO')!,
                'assets/images/promo.png'),
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MYTRANSACTION')!,
                'assets/images/pro_th.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        //_getDrawerItem(getTranslated(context, 'CHANGE_THEME_LBL')!,
           // 'assets/images/pro_theme.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'CHANGE_LANGUAGE_LBL')!,
            'assets/images/pro_language.svg'),
        //  CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'CHANGE_PASS_LBL')!,
                'assets/images/pro_pass.svg'),
        // _getDivider(),
        CUR_USERID == '' || CUR_USERID == null || !refer
            ? Container()
            : _getDrawerItem(getTranslated(context, 'REFEREARN')!,
                'assets/images/pro_referral.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        _getDrawerItem(getTranslated(context, 'CUSTOMER_SUPPORT')!,
            'assets/images/pro_customersupport.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'ABOUT_LBL')!,
            'assets/images/pro_aboutus.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'CONTACT_LBL')!,
            'assets/images/pro_contact_us.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'FAQS')!, 'assets/images/pro_faq.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'PRIVACY')!, 'assets/images/pro_pp.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'TERM')!, 'assets/images/pro_tc.svg'),
        _getDrawerItem(getTranslated(context, 'SHIPPING_POLICY_LBL')!,
            'assets/images/pro_shipping_policy.svg'),
        _getDrawerItem(getTranslated(context, 'RETURN_POLICY_LBL')!,
            'assets/images/pro_return_policy.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'RATE_US')!, 'assets/images/pro_rateus.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'SHARE_APP')!,
            'assets/images/pro_share.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == '' || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'LOGOUT')!,
                'assets/images/pro_logout.svg'),
      ],
    );
  }

  _getDrawerItem(String title, String img) {
    return Card(
      elevation: 0.1,
      child: ListTile(
        trailing: const Icon(
          Icons.navigate_next,
          color: colors.primary,
        ),
        leading: title == getTranslated(context, 'YOUR_PROM_CO')
            ? Image.asset(
                img,
                height: 25,
                width: 25,
                color: colors.primary,
              )
            : SvgPicture.asset(
                img,
                height: 25,
                width: 25,
                color: colors.primary,
              ),
        dense: true,
        title: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.lightBlack, fontSize: 15),
        ),
        onTap: () {
          if (title == getTranslated(context, 'MY_ORDERS_LBL')) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const MyOrder(),
              ),
            );

            //sendAndRetrieveMessage();
          } else if (title == getTranslated(context, 'MYTRANSACTION')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const TransactionHistory(),
                ));
          } else if (title == getTranslated(context, 'MYWALLET')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const MyWallet(),
                ));
          } else if (title == getTranslated(context, 'YOUR_PROM_CO')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const PromoCode(from: "Profile"),
                ));
          } else if (title == getTranslated(context, 'SETTING')) {
            CUR_USERID == null
                ? Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Login(),
                    ))
                : Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Setting(),
                    ));
          } else if (title == getTranslated(context, 'MANAGE_ADD_LBL')) {
            CUR_USERID == null
                ? Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Login(),
                    ))
                : Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const ManageAddress(
                        home: true,
                      ),
                    ));
          } else if (title == getTranslated(context, 'REFEREARN')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ReferEarn(),
                ));
          } else if (title == getTranslated(context, 'CONTACT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CONTACT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CUSTOMER_SUPPORT')) {
            CUR_USERID == null
                ? Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Login(),
                    ))
                : Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const CustomerSupport()));
          } else if (title == getTranslated(context, 'TERM')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'TERM'),
                  ),
                ));
          } else if (title == getTranslated(context, 'PRIVACY')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'PRIVACY'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RATE_US')) {
            _openStoreListing();
          } else if (title == getTranslated(context, 'SHARE_APP')) {
            var str =
                "$appName\n\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n\n ${getTranslated(context, 'IOSLBL')}\n$iosLink";

            Share.share(str);
          } else if (title == getTranslated(context, 'ABOUT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'ABOUT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'SHIPPING_POLICY_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'SHIPPING_POLICY_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RETURN_POLICY_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'RETURN_POLICY_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'FAQS')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Faqs(
                    title: getTranslated(context, 'FAQS'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CHANGE_THEME_LBL')) {
            openChangeThemeBottomSheet();
          } else if (title == getTranslated(context, 'LOGOUT')) {
            logOutDailog();
          } else if (title == getTranslated(context, 'CHANGE_PASS_LBL')) {
            openChangePasswordBottomSheet();
          } else if (title == getTranslated(context, 'CHANGE_LANGUAGE_LBL')) {
            openChangeLanguageBottomSheet();
          }
        },
      ),
    );
  }

  List<Widget> themeListView(BuildContext ctx) {
    return themeList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  _updateState(index, ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: curTheme == index
                                  ? colors.grad2Color
                                  : Theme.of(context).colorScheme.white,
                              border: Border.all(color: colors.grad2Color),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: curTheme == index
                                    ? Icon(
                                        Icons.check,
                                        size: 17.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                      )
                                    : Icon(
                                        Icons.check_box_outline_blank,
                                        size: 15.0,
                                        color:
                                            Theme.of(context).colorScheme.white,
                                      )),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                themeList[index]!,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack),
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  _updateState(int position, BuildContext ctx) {
    curTheme = position;

    onThemeChanged(themeList[position]!, ctx);
  }

  void onThemeChanged(
    String value,
    BuildContext ctx,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == getTranslated(ctx, 'SYSTEM_DEFAULT')) {
      themeNotifier.setThemeMode(ThemeMode.system);
      prefs.setString(APP_THEME, DEFAULT_SYSTEM);

      var brightness = SchedulerBinding.instance!.window.platformBrightness;
      if (mounted) {
        setState(() {
          isDark = brightness == Brightness.dark;
          if (isDark) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
          } else {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
          }
        });
      }
    } else if (value == getTranslated(ctx, 'LIGHT_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.light);
      prefs.setString(APP_THEME, LIGHT);
      if (mounted) {
        setState(() {
          isDark = false;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        });
      }
    } else if (value == getTranslated(ctx, 'DARK_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.dark);
      prefs.setString(APP_THEME, DARK);
      if (mounted) {
        setState(() {
          isDark = true;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        });
      }
    }
    ISDARK = isDark.toString();

    //Provider.of<SettingProvider>(context,listen: false).setPrefrence(APP_THEME, value);
  }

  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: 'microsoftStoreId',
      );

  logOutDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          content: Text(
            getTranslated(context, 'LOGOUTTXT')!,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  getTranslated(context, 'NO')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                }),
            TextButton(
                child: Text(
                  getTranslated(context, 'YES')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  SettingProvider settingProvider =
                      Provider.of<SettingProvider>(context, listen: false);
                  settingProvider.clearUserSession(context);
                  //favList.clear();
                  context.read<FavoriteProvider>().setFavlist([]);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home', (Route<dynamic> route) => false);
                })
          ],
        );
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    languageList = [
      getTranslated(context, 'ENGLISH_LAN'),
      getTranslated(context, 'CHINESE_LAN'),
      getTranslated(context, 'SPANISH_LAN'),
      getTranslated(context, 'HINDI_LAN'),
      getTranslated(context, 'ARABIC_LAN'),
      getTranslated(context, 'RUSSIAN_LAN'),
      getTranslated(context, 'JAPANISE_LAN'),
      getTranslated(context, 'GERMAN_LAN')
    ];
    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME')
    ];

    themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getHeader(),
              _getDrawer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (mounted) {
              onBtnSelected!();
            }
          },
          child: Container(
            margin: const EdgeInsetsDirectional.only(end: 20),
            height: 80,
            width: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    width: 1.0, color: Theme.of(context).colorScheme.white)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child:
                  Consumer<UserProvider>(builder: (context, userProvider, _) {
                return userProvider.profilePic != ''
                    ? FadeInImage(
                        fadeInDuration: const Duration(milliseconds: 150),
                        image:
                            CachedNetworkImageProvider(userProvider.profilePic),
                        height: 64.0,
                        width: 64.0,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) =>
                            erroWidget(64),
                        placeholder: placeHolder(64),
                      )
                    : imagePlaceHolder(62, context);
              }),
            ),
          ),
        ),
        if (CUR_USERID != null)
          Positioned.directional(
              textDirection: Directionality.of(context),
              end: 20,
              bottom: 5,
              child: Container(
                height: 20,
                width: 20,
                child: InkWell(
                  child: const Icon(
                    Icons.edit,
                    color: colors.whiteTemp,
                    size: 10,
                  ),
                  onTap: () {
                    if (mounted) {
                      onBtnSelected!();
                    }
                  },
                ),
                decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(20),
                    ),
                    border: Border.all(color: colors.primary)),
              )),
      ],
    );
  }

  void openChangeUserDetailsBottomSheet() {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0))),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: _changeUserDetailsKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    bottomSheetHandle(),
                    bottomsheetLabel('EDIT_PROFILE_LBL'),
                    Selector<UserProvider, String>(
                        selector: (_, provider) => provider.profilePic,
                        builder: (context, profileImage, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: getUserImage(profileImage, _imgFromGallery),
                          );
                        }),
                    Selector<UserProvider, String>(
                        selector: (_, provider) => provider.curUserName,
                        builder: (context, userName, child) {
                          return setNameField(userName);
                        }),
                    Selector<UserProvider, String>(
                        selector: (_, provider) => provider.email,
                        builder: (context, userEmail, child) {
                          return setEmailField(userEmail);
                        }),
                    saveButton(getTranslated(context, 'SAVE_LBL')!, () {
                      validateAndSave(_changeUserDetailsKey);
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget bottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.lightBlack),
        height: 5,
        width: MediaQuery.of(context).size.width * 0.3,
      ),
    );
  }

  Widget bottomsheetLabel(String labelName) => Padding(
        padding: const EdgeInsets.only(top: 30.0, bottom: 20),
        child: getHeading(labelName),
      );

  void _imgFromGallery() async {
    var result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var image = File(result.files.single.path!);
      if (mounted) {
        await setProfilePic(image);
      }
    } else {
      // User canceled the picker
    }
  }

  Future<void> setProfilePic(File _image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var image;
        var request = http.MultipartRequest('POST', (getUpdateUserApi));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID!;

        final mimeType = lookupMimeType(_image.path);

        var extension = mimeType!.split('/');

        var pic = await http.MultipartFile.fromPath(
          IMAGE,
          _image.path,
          contentType: MediaType('image', extension[1]),
        );
        request.files.add(pic);
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        bool error = getdata['error'];
        String? msg = getdata['message'];

        if (!error) {
          var data = getdata['data'];
          for (var i in data) {
            image = i[IMAGE];
          }
          var settingProvider =
              Provider.of<SettingProvider>(context, listen: false);
          settingProvider.setPrefrence(IMAGE, image!);
          var userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setProfilePic(image!);
          setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!);
        } else {
          setSnackbar(msg!);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Widget setNameField(String userName) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              //initialValue: nameController.text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold),
              controller: nameController,
              decoration: InputDecoration(
                  label: Text(
                    getTranslated(
                      context,
                      'NAME_LBL',
                    )!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  fillColor: Theme.of(context).colorScheme.primary,
                  border: InputBorder.none),
              validator: (val) => validateUserName(
                  val!,
                  getTranslated(context, 'USER_REQUIRED'),
                  getTranslated(context, 'USER_LENGTH')),
            ),
          ),
        ),
      );

  Widget setEmailField(String email) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold),
              controller: emailController,
              decoration: InputDecoration(
                  label: Text(
                    getTranslated(context, 'EMAILHINT_LBL')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  fillColor: Theme.of(context).colorScheme.primary,
                  border: InputBorder.none),
              validator: (val) => validateEmail(
                  val!,
                  getTranslated(context, 'EMAIL_REQUIRED'),
                  getTranslated(context, 'VALID_EMAIL')),
            ),
          ),
        ),
      );

  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: Theme.of(context).colorScheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              onPressed: onBtnSelected,
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> validateAndSave(GlobalKey<FormState> key) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
      if (key == _changePwdKey) {
        await setUpdateUser(CUR_USERID!, passwordController.text,
            newpassController.text, '', '');
        passwordController.clear();
        newpassController.clear();
        passwordController.clear();
        confirmpassController.clear();
      } else if (key == _changeUserDetailsKey) {
        setUpdateUser(
            CUR_USERID!, '', '', nameController.text, emailController.text);
      }
      return true;
    }
    return false;
  }

  Widget getHeading(String title) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context).textTheme.headline6!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.fontColor),
    );
  }

  void openChangePasswordBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      bottomsheetLabel('CHANGE_PASS_LBL'),
                      setCurrentPasswordField(),
                      setForgotPwdLable(),
                      newPwdField(),
                      confirmPwdField(),
                      saveButton(getTranslated(context, 'SAVE_LBL')!, () {
                        validateAndSave(_changePwdKey);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  void openChangeLanguageBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      bottomsheetLabel('CHOOSE_LANGUAGE_LBL'),
                      StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setModalState) {
                          return SingleChildScrollView(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: getLngList(context, setModalState)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  void openChangeThemeBottomSheet() {
    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME')
    ];

    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      bottomsheetLabel('CHOOSE_THEME_LBL'),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: themeListView(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget setCurrentPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            obscuringCharacter: '*',
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
            ),
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'CUR_PASS_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              currentPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PWD_LENGTH')),
          ),
        ),
      ),
    );
  }

  Widget setForgotPwdLable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          child: Text(getTranslated(context, 'FORGOT_PASSWORD_LBL')!),
          onTap: () {
            Navigator.of(context)
                .push(CupertinoPageRoute(builder: (context) => SendOtp()));
          },
        ),
      ),
    );
  }

  Widget newPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: newpassController,
            obscureText: true,
            obscuringCharacter: '*',
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
            ),
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'NEW_PASS_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              newPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PWD_LENGTH')),
          ),
        ),
      ),
    );
  }

  Widget confirmPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: confirmpassController,
            focusNode: confirmPwdFocus,
            obscureText: true,
            obscuringCharacter: '*',
            style: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold),
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'CONFIRMPASSHINT_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            validator: (value) {
              if (value!.isEmpty) {
                return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
              }
              if (value != newPwd) {
                confirmpassController.text = '';
                confirmPwdFocus.requestFocus();
                return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
              } else {
                return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
