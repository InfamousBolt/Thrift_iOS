import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Model/Notification_Model.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Screen/Chat.dart';
import 'package:eshop_multivendor/Screen/Customer_Support.dart';
import 'package:eshop_multivendor/Screen/MyOrder.dart';
import 'package:eshop_multivendor/Screen/My_Wallet.dart';
import 'package:eshop_multivendor/Screen/Product_Detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';

class NotificationList extends StatefulWidget {

  const NotificationList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateNoti();
}



class StateNoti extends State<NotificationList> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController controller = ScrollController();
  List<NotificationModel> tempList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<NotificationModel> notiList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;


  @override
  void initState() {
    getNotification();
    controller.addListener(_scrollListener);
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
    super.initState();
  }

  @override
  void dispose() {
    buttonController!.dispose();
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
                  getNotification();
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

  Future<void> _refresh() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    offset = 0;
    total = 0;
    notiList.clear();
    return getNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(getTranslated(context,'NOTIFICATION')!, context),
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : notiList.isEmpty
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: kToolbarHeight),
                        child: Center(
                            child: Text(getTranslated(context, 'noNoti')!)))
                    : RefreshIndicator(
                         color: colors.primary,
                        key: _refreshIndicatorKey,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          // shrinkWrap: true,
                          controller: controller,
                          itemCount: (offset < total)
                              ? notiList.length + 1
                              : notiList.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return (index == notiList.length && isLoadingmore)
                                ? singleItemSimmer(context)
                                : listItem(index);
                          },
                        ))
            : noInternet(context));
  }


  Future<void> getProduct(String id, int index, int secPos, bool list) async {


    try {
      var parameter = {
        ID: id,
      };

      Response response =
      await post(getProductApi, headers: headers, body: parameter)
          .timeout(const Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      bool error = getdata['error'];
      String? msg = getdata['message'];
      if (!error) {
        var data = getdata['data'];

        List<Product> items = [];

        items =
            (data as List).map((data) => Product.fromJson(data)).toList();

        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => ProductDetail(
              index: int.parse(id),
              model: items[0],
              secPos: secPos,
              list: list,
            )));
      } else {}
    } on Exception {}
  }

  Widget listItem(int index) {
    NotificationModel model = notiList[index];
    return InkWell(
      onTap: (){
        if (model.type == 'products') {
          getProduct(model.typeId!, 0, 0, true);
        } else if (model.type == 'categories') {
          Navigator.of(context).pop(true);

          /*Navigator.push(context,
              (CupertinoPageRoute(builder: (context) => AllCategory())));*/
        } else if (model.type == 'wallet') {
          Navigator.push(
              context, (CupertinoPageRoute(builder: (context) => const MyWallet())));
        } else if (model.type == 'order') {
          Navigator.push(
              context, (CupertinoPageRoute(builder: (context) => const MyOrder())));
        } else if (model.type == 'ticket_message') {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => Chat(
                  id: model.id,
                  status: '',
                )),
          );
        } else if (model.type == 'ticket_status') {
          Navigator.push(context,
              CupertinoPageRoute(builder: (context) => const CustomerSupport()));
        } else {
          setSnackbar('It is a normal Notification');
        }
      },
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.date!,
                      style: const TextStyle(color: colors.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        model.title!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(model.desc!)
                  ],
                ),
              ),
              model.img != null && model.img != ''
                  ? GestureDetector(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Hero(
                          tag: model.id!,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              model.img!,
                            ),
                            radius: 25,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(PageRouteBuilder(
                            opaque: false,
                            barrierDismissible: true,
                            pageBuilder: (BuildContext context, _, __) {
                              return AlertDialog(
                                elevation: 0,
                                contentPadding: const EdgeInsets.all(0),
                                backgroundColor: Colors.transparent,
                                content: Hero(
                                  tag: model.id!,
                                  child: FadeInImage(
                                    image: CachedNetworkImageProvider(model.img!),
                                    fadeInDuration: const Duration(milliseconds: 150),
                                    placeholder: placeHolder(150),
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(150),
                                  ),
                                ),
                              );
                            }));

                        // return showDialog(
                        //     context: context,
                        //     builder: (BuildContext context) {
                        //       return StatefulBuilder(builder:
                        //           (BuildContext context, StateSetter setStater) {
                        //         return AlertDialog(
                        //             backgroundColor: Colors.transparent,
                        //             shape: RoundedRectangleBorder(
                        //                 borderRadius: BorderRadius.all(
                        //                     Radius.circular(5.0))),
                        //             content: Hero(
                        //               tag: model.id,
                        //               child: FadeInImage(
                        //                 image: NetworkImage(model.img),
                        //                 fadeInDuration:
                        //                     Duration(milliseconds: 150),
                        //                 placeholder: placeHolder(150),
                        //               ),
                        //             ));
                        //       });
                        //     });
                      },
                    )
                  : Container(
                      height: 0,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getNotification() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        Response response =
            await post(getNotificationApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata['error'];
          String? msg = getdata['message'];

          if (!error) {
            total = int.parse(getdata['total']);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata['data'];
              tempList = (data as List)
                  .map((data) => NotificationModel.fromJson(data))
                  .toList();

              notiList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            if (msg != 'Products Not Found !') setSnackbar(msg!);
            isLoadingmore = false;
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        if (mounted) {
          setState(() {
            _isLoading = false;
            isLoadingmore = false;
          });
        }
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
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

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            if (offset < total) getNotification();
          });
        }
      }
    }
  }
}
