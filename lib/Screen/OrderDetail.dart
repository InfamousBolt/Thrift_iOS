import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/AppBtn.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Model/Order_Model.dart';
import 'package:eshop_multivendor/Screen/Seller_Details.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/User.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class OrderDetail extends StatefulWidget {
  final OrderModel? model;

  // final Function? updateHome;

  const OrderDetail({Key? key, this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<User> tempList = [];
  late bool _isCancleable, _isReturnable;
  bool _isProgress = false;
  int offset = 0;
  int total = 0;
  List<User> reviewList = [];
  bool isLoadingmore = true;
  bool _isReturnClick = true;
  String? proId, image;
  final InAppReview _inAppReview = InAppReview.instance;
  List<File> files = [];

  int _selectedTabIndex = 0;
  late TabController _tabController;

  List<File> reviewPhotos = [];
  TextEditingController commentTextController = TextEditingController();
  double curRating = 0.0;
  Future<List<Directory>?>? _externalStorageDirectories;

  @override
  void initState() {
    super.initState();
    files.clear();
    reviewPhotos.clear();

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
    _tabController = TabController(
      length: 5,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    _externalStorageDirectories =
        getExternalStorageDirectories(type: StorageDirectory.documents);
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
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    var model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;

    if (model.listStatus.contains(PLACED)) {
      pDate = model.listDate![model.listStatus.indexOf(PLACED)];

      if (pDate != null) {
        List d = pDate.split(' ');
        pDate = d[0] + '\n' + d[1];
      }
    }
    if (model.listStatus.contains(PROCESSED)) {
      prDate = model.listDate![model.listStatus.indexOf(PROCESSED)];
      if (prDate != null) {
        List d = prDate.split(' ');
        prDate = d[0] + '\n' + d[1];
      }
    }
    if (model.listStatus.contains(SHIPED)) {
      sDate = model.listDate![model.listStatus.indexOf(SHIPED)];
      if (sDate != null) {
        List d = sDate.split(' ');
        sDate = d[0] + '\n' + d[1];
      }
    }
    if (model.listStatus.contains(DELIVERD)) {
      dDate = model.listDate![model.listStatus.indexOf(DELIVERD)];
      if (dDate != null) {
        List d = dDate.split(' ');
        dDate = d[0] + '\n' + d[1];
      }
    }
    if (model.listStatus.contains(CANCLED)) {
      cDate = model.listDate![model.listStatus.indexOf(CANCLED)];
      if (cDate != null) {
        List d = cDate.split(' ');
        cDate = d[0] + '\n' + d[1];
      }
    }
    if (model.listStatus.contains(RETURNED)) {
      rDate = model.listDate![model.listStatus.indexOf(RETURNED)];
      if (rDate != null) {
        List d = rDate.split(' ');
        rDate = d[0] + '\n' + d[1];
      }
    }

    _isCancleable = model.isCancleable == '1' ? true : false;
    _isReturnable = model.isReturnable == '1' ? true : false;

    return WillPopScope(
      onWillPop: () async {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar:
            getSimpleAppBar(getTranslated(context, 'ORDER_DETAIL')!, context),
        body: _isNetworkAvail
            ? Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: getSubHeadingsTabBar(),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            getOrderDetails(model),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, PROCESSED),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, DELIVERD),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, CANCLED),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, RETURNED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context),
      ),
    );
  }

/*  returnable() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.grad1Color, colors.grad2Color],
            stops: [0, 1]),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
      ),
      width: deviceWidth,
      child: InkWell(
        onTap: _isReturnClick
            ? () {
          setState(() {
            _isReturnClick = false;
            _isProgress = true;
          });
          cancelOrder(RETURNED, updateOrderApi, widget.model!.id);
        }
            : null,
        child: Center(
            child: Text(
              getTranslated(context, 'RETURN_ORDER')!,
              style: Theme
                  .of(context)
                  .textTheme
                  .button!
                  .copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.white),
            )),
      ),
    );
  }*/

  /* cancelable() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.grad1Color, colors.grad2Color],
            stops: [0, 1]),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
      ),
      width: deviceWidth,
      child: InkWell(
        onTap: _isReturnClick
            ? () {
          setState(() {
            _isReturnClick = false;
            _isProgress = true;
          });
          cancelOrder(CANCLED, updateOrderApi, widget.model!.id);
        }
            : null,
        child: Center(
            child: Text(
              getTranslated(context, 'CANCEL_ORDER')!,
              style: Theme
                  .of(context)
                  .textTheme
                  .button!
                  .copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.white),
            )),
      ),
    );
  }*/

  priceDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(getTranslated(context, 'PRICE_DETAIL')!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Divider(
                color: Theme.of(context).colorScheme.lightBlack,
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'PRICE_LBL')!} :",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        ' ${getPriceFormat(context, double.parse(widget.model!.subTotal!))!}',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, 'DELIVERY_CHARGE')! + ' ' + ':',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        '+${getPriceFormat(context, double.parse(widget.model!.delCharge!))!}',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        getTranslated(context, 'PROMO_CODE_DIS_LBL')! +
                            ' ' +
                            ':',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        '-${getPriceFormat(context, double.parse(widget.model!.promoDis!))!}',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, 'WALLET_BAL')! + ' ' + ':',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        '-${getPriceFormat(context, double.parse(widget.model!.walBal!))!}',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 15.0, end: 15.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, 'PAYABLE')! + ' ' + ':',
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold)),
                    Text(
                        getPriceFormat(
                            context, double.parse(widget.model!.payable!))!,
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ])));
  }

  shippingDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(getTranslated(context, 'SHIPPING_DETAIL')!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Divider(
                color: Theme.of(context).colorScheme.lightBlack,
              ),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(
                    widget.model!.userAddressName! + ',',
                  )),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.address!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2))),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.mobile!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                      ))),
            ])));
  }

  productItem(OrderItem orderItem, OrderModel model) {
    String? pDate, prDate, sDate, dDate, cDate, rDate, aDate;

    if (orderItem.listStatus!.contains(WAITING)) {
      aDate = orderItem.listDate![orderItem.listStatus!.indexOf(WAITING)];
    }
    if (orderItem.listStatus!.contains(PLACED)) {
      pDate = orderItem.listDate![orderItem.listStatus!.indexOf(PLACED)];
    }
    if (orderItem.listStatus!.contains(PROCESSED)) {
      prDate = orderItem.listDate![orderItem.listStatus!.indexOf(PROCESSED)];
    }
    if (orderItem.listStatus!.contains(SHIPED)) {
      sDate = orderItem.listDate![orderItem.listStatus!.indexOf(SHIPED)];
    }
    if (orderItem.listStatus!.contains(DELIVERD)) {
      dDate = orderItem.listDate![orderItem.listStatus!.indexOf(DELIVERD)];
    }
    if (orderItem.listStatus!.contains(CANCLED)) {
      cDate = orderItem.listDate![orderItem.listStatus!.indexOf(CANCLED)];
    }
    if (orderItem.listStatus!.contains(RETURNED)) {
      rDate = orderItem.listDate![orderItem.listStatus!.indexOf(RETURNED)];
    }
    List att = [], val = [];
    if (orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }

    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: FadeInImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          image: CachedNetworkImageProvider(orderItem.image!),
                          height: 90.0,
                          width: 90.0,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(90),
                          placeholder: placeHolder(90),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderItem.name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack,
                                      fontWeight: FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            orderItem.attr_name!.isNotEmpty
                                ? ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: att.length,
                                    itemBuilder: (context, index) {
                                      return Row(children: [
                                        Flexible(
                                          child: Text(
                                            att[index].trim() + ':',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack2),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 5.0),
                                          child: Text(
                                            val[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack),
                                          ),
                                        )
                                      ]);
                                    })
                                : Container(),

                            Row(children: [
                              Text(
                                getTranslated(context, 'QUANTITY_LBL')! + ':',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack2),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 5.0),
                                child: Text(
                                  orderItem.qty!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack),
                                ),
                              )
                            ]),
                            Text(
                              getPriceFormat(
                                  context, double.parse(orderItem.price!))!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            ),
                            //  Text(orderItem.status)
                          ],
                        ),
                      ),
                    )
                  ],
                ),

                Divider(
                  color: Theme.of(context).colorScheme.lightBlack,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      pDate != null ? getPlaced(pDate) : getPlaced(aDate!),
                      getProcessed(prDate, cDate),
                      getShipped(sDate, cDate),
                      getDelivered(dDate, cDate),
                      getCanceled(cDate),
                      getReturned(orderItem, rDate, model),
                    ],
                  ),
                ),
                Divider(
                  color: Theme.of(context).colorScheme.lightBlack,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${getTranslated(context, "STORE_NAME")!} : ",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${getTranslated(context, "OTP")!} : ",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontWeight: FontWeight.bold),
                          ),
                          orderItem.courier_agency! != ''
                              ? Text(
                                  "${getTranslated(context, 'COURIER_AGENCY')!}: ",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack,
                                      fontWeight: FontWeight.bold),
                                )
                              : Container(),
                          orderItem.tracking_id! != ''
                              ? Text(
                                  "${getTranslated(context, 'TRACKING_ID')!}: ",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack,
                                      fontWeight: FontWeight.bold),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            child: Text(
                              '${orderItem.store_name}',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                  decoration: TextDecoration.underline),
                            ),
                            onTap: () {
                              Navigator.of(context).push(CupertinoPageRoute(
                                  builder: (context) => SellerProfile(
                                        sellerStoreName: orderItem.store_name,
                                        sellerRating: orderItem.seller_rating,
                                        sellerImage: orderItem.seller_profile,
                                        sellerName: orderItem.seller_name,
                                        sellerID: orderItem.seller_id,
                                        storeDesc: orderItem.store_description,
                                      )));
                            },
                          ),
                          Text(
                            '${orderItem.item_otp} ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                            ),
                          ),
                          orderItem.courier_agency! != ''
                              ? Text(
                                  orderItem.courier_agency!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack2,
                                  ),
                                )
                              : Container(),
                          orderItem.tracking_id! != ''
                              ? RichText(
                                  text: TextSpan(children: [
                                  TextSpan(
                                    text: '',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                      text: orderItem.courier_agency!,
                                      style: const TextStyle(
                                          color: colors.primary,
                                          decoration: TextDecoration.underline),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          var url = '${orderItem.tracking_url}';

                                          if (await canLaunch(url)) {
                                            await launch(url);
                                          } else {
                                            setSnackbar(getTranslated(
                                                context, 'URL_ERROR')!);
                                          }
                                        })
                                ]))
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),

                /*       model.payMethod == "Bank Transfer"
                    ? ListTile(
                  dense: true,
                  title: Text(
                    getTranslated(context, 'BANKRECEIPT')!,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                  ),
                  trailing: IconButton(
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: colors.primary,
                        size: 25.0,
                      ),
                      onPressed: () {
                        _imgFromGallery();
                      }),
                )
                    : Container(),*/

                /*  model.payMethod == "Bank Transfer"
                    ? bankProof(model)
                    : Container(),
*/

                Container(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20.0, end: 20.0, top: 5),
                  height: files.isNotEmpty ? 180 : 0,
                  child: Row(
                    children: [
                      Expanded(
                          child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: files.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) {
                          return InkWell(
                            child: Stack(
                              alignment: AlignmentDirectional.topEnd,
                              children: [
                                Image.file(
                                  files[i],
                                  width: 180,
                                  height: 180,
                                ),
                                Container(
                                    color:
                                        Theme.of(context).colorScheme.black26,
                                    child: const Icon(
                                      Icons.clear,
                                      size: 15,
                                    ))
                              ],
                            ),
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  files.removeAt(i);
                                });
                              }
                            },
                          );
                        },
                      )),
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.lightWhite,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0))),
                          child: Text(
                            getTranslated(context, 'SUBMIT_LBL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor),
                          ),
                        ),
                        onTap: () {
                          sendBankProof();
                        },
                      ),
                    ],
                  ),
                ),

                /////
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (orderItem.status == DELIVERD)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            openBottomSheet(context, orderItem);
                          },
                          icon: const Icon(Icons.rate_review_outlined,
                              color: colors.primary),
                          label: Text(
                            orderItem.userReviewRating != '0'
                                ? getTranslated(context, 'UPDATE_REVIEW_LBL')!
                                : getTranslated(context, 'WRITE_REVIEW_LBL')!,

                            style: const TextStyle(color: colors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.btnColor),
                          ),
                        ),
                      ),
                    if (!orderItem.listStatus!.contains(DELIVERD) &&
                        (!orderItem.listStatus!.contains(RETURNED)) &&
                        orderItem.isCancle == '1' &&
                        orderItem.isAlrCancelled == '0')
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Align(
                            alignment: Alignment.bottomRight,
                            child: OutlinedButton(
                              onPressed: _isReturnClick
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                              getTranslated(
                                                  context, 'ARE_YOU_SURE?')!,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor),
                                            ),
                                            content: Text(
                                              'Would you like to cancel this product?',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'YES')!,
                                                  style: const TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    _isReturnClick = false;
                                                    _isProgress = true;
                                                  });
                                                  cancelOrder(
                                                      CANCLED,
                                                      updateOrderItemApi,
                                                      orderItem.id);
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  getTranslated(context, 'NO')!,
                                                  style: const TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              )
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  : null,
                              child:
                                  Text(getTranslated(context, 'ITEM_CANCEL')!),
                            )),
                      )
                    else
                      (orderItem.listStatus!.contains(DELIVERD) &&
                              orderItem.isReturn == '1' &&
                              orderItem.isAlrReturned == '0')
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: OutlinedButton(
                                onPressed: _isReturnClick
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                getTranslated(
                                                    context, 'ARE_YOU_SURE?')!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                              ),
                                              content: Text(
                                                'Would you like to return this product?',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text(
                                                    getTranslated(
                                                        context, 'YES')!,
                                                    style: const TextStyle(
                                                        color: colors.primary),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      _isReturnClick = false;
                                                      _isProgress = true;
                                                    });
                                                    cancelOrder(
                                                        RETURNED,
                                                        updateOrderItemApi,
                                                        orderItem.id);
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text(
                                                    getTranslated(
                                                        context, 'NO')!,
                                                    style: const TextStyle(
                                                        color: colors.primary),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    : null,
                                child: Text(
                                    getTranslated(context, 'ITEM_RETURN')!),
                              ),
                            )
                          : Container(),
                  ],
                ),
              ],
            )));
  }

  bankProof(OrderModel model) {
    String status = model.attachList![0].bankTranStatus!;
    Color clr;
    if (status == '0') {
      status = 'Pending';
      clr = Colors.cyan;
    } else if (status == '1') {
      status = 'Rejected';
      clr = Colors.red;
    } else {
      status = 'Accepted';
      clr = Colors.green;
    }

    return Card(
        elevation: 0,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: model.attachList!.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        child: Text(
                          'Attachment ' + (i + 1).toString(),
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).colorScheme.fontColor),
                        ),
                        onTap: () {
                          _launchURL(model.attachList![i].attachment!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
                decoration: BoxDecoration(
                    color: clr, borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(status),
                ))
          ],
        ));
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';

  _imgFromGallery() async {
    var result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      files = result.paths.map((path) => File(path!)).toList();
      if (mounted) setState(() {});
    } else {
      // User canceled the picker
    }
  }

  getPlaced(String pDate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Icon(
          Icons.circle,
          color: colors.primary,
          size: 15,
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_NPLACED')!,
                style: const TextStyle(fontSize: 8),
              ),
              Text(
                pDate,
                style: const TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getProcessed(String? prDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        thickness: 2,
                        color: prDate == null ? Colors.grey : colors.primary,
                      )),
                  Icon(
                    Icons.circle,
                    color: prDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_PROCESSED')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      prDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          )
        : prDate == null
            ? Container()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          thickness: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        color: colors.primary,
                        size: 15,
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'ORDER_PROCESSED')!,
                          style: const TextStyle(fontSize: 8),
                        ),
                        Text(
                          prDate,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              );
  }

  getShipped(String? sDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: sDate == null ? Colors.grey : colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    color: sDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_SHIPPED')!,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      sDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          )
        : sDate == null
            ? Container()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    children: const [
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          thickness: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        color: colors.primary,
                        size: 15,
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'ORDER_SHIPPED')!,
                          style: const TextStyle(fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          sDate,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              );
  }

  getDelivered(String? dDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: dDate == null ? Colors.grey : colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    color: dDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_DELIVERED')!,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      dDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : Container();
  }

  getCanceled(String? cDate) {
    return cDate != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: const [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.cancel_rounded,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_CANCLED')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      cDate,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : Container();
  }

  getReturned(OrderItem item, String? rDate, OrderModel model) {
    return item.listStatus!.contains(RETURNED)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: const [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.cancel_rounded,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                  margin: const EdgeInsetsDirectional.only(start: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslated(context, 'ORDER_RETURNED')!,
                        style: const TextStyle(fontSize: 8),
                      ),
                      Text(
                        rDate ?? ' ',
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
            ],
          )
        : Container();
  }

  Future<void> cancelOrder(String status, Uri api, String? id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {ORDERID: id, STATUS: status};
        var response = await post(api, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String msg = getdata['message'];
        if (!error) {
          Future.delayed(const Duration(seconds: 1)).then((_) async {
            Navigator.pop(context, 'update');
          });
        }

        if (mounted) {
          setState(() {
            _isProgress = false;
            _isReturnClick = true;
          });
        }
        setSnackbar(msg);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
          _isReturnClick = true;
        });
      }
    }
  }

  setSnackbar(String msg) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  DwnInvoice() {
    return FutureBuilder<List<Directory>?>(
        future: _externalStorageDirectories,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Card(
            elevation: 0,
            child: InkWell(
                child: ListTile(
                  dense: true,
                  trailing: const Icon(
                    Icons.keyboard_arrow_right,
                    color: colors.primary,
                  ),
                  leading: const Icon(
                    Icons.receipt,
                    color: colors.primary,
                  ),
                  title: Text(
                    getTranslated(context, 'DWNLD_INVOICE')!,
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack),
                  ),
                ),
                onTap: () async {
                  final status = await Permission.storage.request();
                  // final per=await  Permission.manageExternalStorage.request();

                  if (status == PermissionStatus.granted) {
                    if (mounted) {
                      setState(() {
                        _isProgress = true;
                      });
                    }
                    var targetPath;

                    if (Platform.isIOS) {
                      var target = await getApplicationDocumentsDirectory();
                      targetPath = target.path.toString();
                    } else {
                      if (snapshot.hasData) {
                        targetPath =
                            (snapshot.data as List<Directory>).first.path;


                      }
                    }

                    var targetFileName = 'Invoice_${widget.model!.id}';
                    var generatedPdfFile, filePath;
                    try {
                      generatedPdfFile =
                          await FlutterHtmlToPdf.convertFromHtmlContent(
                              widget.model!.invoice!,
                              targetPath,
                              targetFileName);
                      filePath = generatedPdfFile.path;

                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isProgress = false;
                        });
                        setSnackbar('Something went wrong');
                      }
                      return;
                    }

                    if (mounted) {
                      setState(() {
                        _isProgress = false;
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "${getTranslated(context, 'INVOICE_PATH')} $targetFileName",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.black),
                      ),
                      action: SnackBarAction(
                          label: getTranslated(context, 'VIEW')!,
                          textColor: Theme.of(context).colorScheme.fontColor,
                          onPressed: () async {
                            await OpenFile.open(filePath);
                          }),
                      backgroundColor: Theme.of(context).colorScheme.white,
                      elevation: 1.0,
                    ));
                  }
                }),
          );
        });
  }

  //Old code using download_path_provider
/*  DwnInvoice() {
    return Card(
      elevation: 0,
      child: InkWell(
          child: ListTile(
            dense: true,
            trailing: Icon(
              Icons.keyboard_arrow_right,
              color: colors.primary,
            ),
            leading: Icon(
              Icons.receipt,
              color: colors.primary,
            ),
            title: Text(
              getTranslated(context, 'DWNLD_INVOICE')!,
              style: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(color: Theme.of(context).colorScheme.lightBlack),
            ),
          ),
          onTap: () async {
            final status = await Permission.storage.request();

            if (status == PermissionStatus.granted) {
              if (mounted) {
                setState(() {
                  _isProgress = true;
                });
              }
              var targetPath;

              if (Platform.isIOS) {
                var target = await getApplicationDocumentsDirectory();
                targetPath = target.path.toString();
              } else {
                var downloadsDirectory =
                    await DownloadsPathProvider.downloadsDirectory;
                targetPath = downloadsDirectory!.path.toString();
              }

              var targetFileName = "Invoice_${widget.model!.id}";
              var generatedPdfFile, filePath;
              try {
                generatedPdfFile =
                    await FlutterHtmlToPdf.convertFromHtmlContent(
                        widget.model!.invoice!, targetPath, targetFileName);
                filePath = generatedPdfFile.path;
              } on Exception {
                //  filePath = targetPath + "/" + targetFileName + ".html";
                setSnackbar("error");
                generatedPdfFile =
                    await FlutterHtmlToPdf.convertFromHtmlContent(
                        widget.model!.invoice!, targetPath, targetFileName);
                filePath = generatedPdfFile.path;
              }

              if (mounted) {
                setState(() {
                  _isProgress = false;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  "${getTranslated(context, 'INVOICE_PATH')} $targetFileName",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.black),
                ),
                action: SnackBarAction(
                    label: getTranslated(context, 'VIEW')!,
                    textColor: Theme.of(context).colorScheme.fontColor,
                    onPressed: () async {
                      final result = await OpenFile.open(filePath);
                    }),
                backgroundColor: Theme.of(context).colorScheme.white,
                elevation: 1.0,
              ));
            }
          }),
    );
  }*/

  Future<void> sendBankProof() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }
        var request = http.MultipartRequest('POST', setBankProofApi);
        request.headers.addAll(headers);
        request.fields[ORDER_ID] = widget.model!.id!;


        for (var i = 0; i < files.length; i++) {
          final mimeType = lookupMimeType(files[i].path);

          var extension = mimeType!.split('/');

          var pic = await http.MultipartFile.fromPath(
            ATTACH,
              files[i].path,
            contentType: MediaType('image', extension[1]),
          );

          request.files.add(pic);
        }

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        String msg = getdata['message'];

        files.clear();
        if (mounted) {
          setState(() {
            _isProgress = false;
          });
        }
        setSnackbar(msg);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Widget getSubHeadingsTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBar(
        controller: _tabController,
        tabs: [
          getTab(getTranslated(context, 'ALL_DETAILS')!, 0),
          getTab(getTranslated(context, 'PROCESSING')!, 1),
          getTab(getTranslated(context, 'DELIVERED')!, 2),
          getTab(getTranslated(context, 'CANCELLED')!, 3),
          getTab(getTranslated(context, 'RETURNED')!, 4),
        ],
        indicator: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(50),
          color: colors.primary,
        ),
        isScrollable: true,
        unselectedLabelColor: Theme.of(context).colorScheme.black,
        labelColor: Theme.of(context).colorScheme.white,
        automaticIndicatorColorAdjustment: true,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 1.0),
      ),
    );
  }

  getOrderDetails(OrderModel model) {
    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            getOrderNoAndOTPDetails(model),
            model.delDate != null && model.delDate!.isNotEmpty
                ? Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "${getTranslated(context, 'PREFER_DATE_TIME')!}: ${model.delDate!} - ${model.delTime!}",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2),
                      ),
                    ),
                  )
                : Container(),
            showNote(model),
            //orderPrescriptionAttachments(model),
            bankTransfer(model),
            getSingleProduct(model, ''),
            DwnInvoice(),
            shippingDetails(),
            priceDetails(),
          ],
        ),
      ),
    );
  }

  bankTransfer(OrderModel model) {
    return model.payMethod == 'Bank Transfer'
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'BANKRECEIPT')!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack),
                      ),
                      SizedBox(
                        height: 30,
                        child: IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              color: colors.primary,
                              size: 20.0,
                            ),
                            onPressed: () {
                              _imgFromGallery();
                            }),
                      ),
                    ],
                  ),
                  model.attachList!.isNotEmpty ? bankProof(model) : Container(),
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                        start: 20.0, end: 20.0, top: 5),
                    height: files.isNotEmpty ? 180 : 0,
                    child: Row(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: files.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            return InkWell(
                              child: Stack(
                                alignment: AlignmentDirectional.topEnd,
                                children: [
                                  Image.file(
                                    files[i],
                                    width: 180,
                                    height: 180,
                                  ),
                                  Container(
                                      color:
                                          Theme.of(context).colorScheme.black26,
                                      child: const Icon(
                                        Icons.clear,
                                        size: 15,
                                      ))
                                ],
                              ),
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    files.removeAt(i);
                                  });
                                }
                              },
                            );
                          },
                        )),
                        InkWell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.lightWhite,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0))),
                            child: Text(
                              getTranslated(context, 'SUBMIT_LBL')!,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                            ),
                          ),
                          onTap: () {
                            sendBankProof();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  getSingleProduct(OrderModel model, String activeStatus) {
    var count = 0;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: model.itemList!.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        var orderItem = model.itemList![i];
        proId = orderItem.id;
        if (activeStatus != '') {
          if (orderItem.status == activeStatus) {
            return productItem(orderItem, model);
          }
          if ((orderItem.status == SHIPED || orderItem.status == PLACED) &&
              activeStatus == PROCESSED) {
            return productItem(orderItem, model);
          }
        } else {
          return productItem(orderItem, model);
        }
        count++;
        if (count == model.itemList!.length) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: Text(getTranslated(context, 'noItem')!)),
          );
        }
        return Container();
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  void openBottomSheet(BuildContext context, OrderItem orderItem) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    bottomSheetHandle(),
                    rateTextLabel(),
                    ratingWidget(double.parse(orderItem.userReviewRating!)),
                    writeReviewLabel(),
                    writeReviewField(orderItem.userReviewComment!),
                    getImageField(),
                    sendReviewButton(orderItem),
                  ],
                ),
              ),
            ],
          );
        });
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

  Widget rateTextLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: getHeading('PRODUCT_REVIEW'),
    );
  }

  Widget ratingWidget(double rating) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingBar.builder(
        initialRating: rating,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 5,
        itemSize: 32,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: Colors.amber,
        ),
        onRatingUpdate: (rating) {
          curRating = rating;
        },
      ),
    );
  }

  Widget writeReviewLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        getTranslated(context, 'REVIEW_OPINION')!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.subtitle1!,
      ),
    );
  }

  Widget writeReviewField(String comment) {

    commentTextController.text = comment;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: TextField(
          controller: commentTextController,
          style: Theme.of(context).textTheme.subtitle2,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.lightBlack,
                    width: 1.0)),
            hintText: getTranslated(context, 'REVIEW_HINT_LBL'),
            hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
                color:
                    Theme.of(context).colorScheme.lightBlack2.withOpacity(0.7)),
          ),
        ));
  }

  Widget getImageField() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
      return Container(
        padding:
            const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 5),
        height: 100,
        child: Row(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(50.0)),
                    child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.white,
                          size: 25.0,
                        ),
                        onPressed: () {
                          _reviewImgFromGallery(setModalState);
                        }),
                  ),
                  Text(
                    getTranslated(context, 'ADD_YOUR_PHOTOS')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack,
                        fontSize: 11),
                  )
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
              shrinkWrap: true,
              itemCount: reviewPhotos.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return InkWell(
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Image.file(
                        reviewPhotos[i],
                        width: 100,
                        height: 100,
                      ),
                      Container(
                          color: Theme.of(context).colorScheme.black26,
                          child: const Icon(
                            Icons.clear,
                            size: 15,
                          ))
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      setModalState(() {
                        reviewPhotos.removeAt(i);
                      });
                    }
                  },
                );
              },
            )),
          ],
        ),
      );
    });
  }

  void _reviewImgFromGallery(StateSetter setModalState) async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null) {
      reviewPhotos = result.paths.map((path) => File(path!)).toList();
      if (mounted) setModalState(() {});
    } else {
      // User canceled the picker
    }
  }

  Widget sendReviewButton(OrderItem orderItem) {
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
              onPressed: () {
                if (curRating != 0 ||
                    commentTextController.text != '' ||
                    (reviewPhotos.isNotEmpty)) {
                  Navigator.pop(context);
                  setRating(curRating, commentTextController.text, reviewPhotos,
                      orderItem.productId);
                } else {
                  Navigator.pop(context);
                  setSnackbar(getTranslated(context, 'REVIEW_W')!);
                }
              },
              child: Text( orderItem.userReviewRating != '0'
                  ? getTranslated(context, 'UPDATE_REVIEW_LBL')!
                  : getTranslated(context, 'SEND_REVIEW')!,),
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Text getHeading(
    String title,
  ) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context)
          .textTheme
          .headline6!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }

  Future<void> setRating(
      double rating, String comment, List<File> files, var productID) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest('POST', setRatingApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID!;
        request.fields[PRODUCT_ID] = productID;

        if (files.isEmpty) {
          for (var i = 0; i < files.length; i++) {
            final mimeType = lookupMimeType(files[i].path);

            var extension = mimeType!.split('/');
            var pic = await http.MultipartFile.fromPath(
              IMGS,
              files[i].path,
              contentType: MediaType('image', extension[1]),
            );
            request.files.add(pic);
          }
        }

        if (comment != '') request.fields[COMMENT] = comment;
        if (rating != 0) request.fields[RATING] = rating.toString();
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        bool error = getdata['error'];
        String? msg = getdata['message'];

        if (!error) {
          setSnackbar(msg!);
        } else {
          setSnackbar(msg!);
        }
        commentTextController.text = '';
        files.clear();
        reviewPhotos.clear();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Widget getOrderNoAndOTPDetails(OrderModel model) {
    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${getTranslated(context, "ORDER_ID_LBL")!} - ${model.id}",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  '${model.dateTime}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),
            model.otp != null && model.otp!.isNotEmpty && model.otp != '0'
                ? Text(
                    "${getTranslated(context, "OTP")!} - ${model.otp}",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  getTab(String title, int index) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      height: 35,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
              color: _tabController.index == index
                  ? colors.whiteTemp
                  : Theme.of(context).colorScheme.fontColor),
        ),
      ),
    );
  }

  showNote(OrderModel model) {
    return model.note! != ''
        ? SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${getTranslated(context, 'NOTE')}:",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(model.note!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  /*orderPrescriptionAttachments(OrderModel model) {
    return model.orderPrescriptionAttachments!.isNotEmpty
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslated(context, 'PRESCRIPTION_ATTACHMENTS')!,
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack),
                  ),
                  model.orderPrescriptionAttachments!.isNotEmpty
                      ? prescriptionAttachments(model)
                      : Container(),
                ],
              ),
            ),
          )
        : Container();
  }*/

  /*prescriptionAttachments(OrderModel model) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: model.orderPrescriptionAttachments!.length > 5
                  ? 5
                  : model.orderPrescriptionAttachments!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 8.0, bottom: 8, end: 8),
                  child: InkWell(
                    onTap: () async {
                      if (index == 4) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => ReviewGallary(
                                      orderModel: model,
                                      imageList:
                                          model.orderPrescriptionAttachments,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                // transitionDuration: Duration(seconds: 1),
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      imageList:
                                          model.orderPrescriptionAttachments,
                                    )));
                      }
                    },
                    child: Stack(
                      children: [
                        FadeInImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          image: CachedNetworkImageProvider(
                              model.orderPrescriptionAttachments![index]),
                          height: 100.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                          //  errorWidget: (context, url, e) => placeHolder(50),
                          placeholder: placeHolder(80),
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(80),
                        ),
                        index == 4
                            ? Container(
                                height: 100.0,
                                width: 80.0,
                                color: colors.black54,
                                child: Center(
                                    child: Text(
                                  "+${model.orderPrescriptionAttachments!.length - 5}",
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold),
                                )),
                              )
                            : Container()
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }*/
}
