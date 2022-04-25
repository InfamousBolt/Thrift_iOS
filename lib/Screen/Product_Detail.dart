import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/SqliteData.dart';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/FavoriteProvider.dart';
import 'package:eshop_multivendor/Provider/HomeProvider.dart';
import 'package:eshop_multivendor/Provider/ProductDetailProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Cart.dart';
import 'package:eshop_multivendor/Screen/CompareList.dart';
import 'package:eshop_multivendor/Screen/ReviewList.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import 'Favorite.dart';
import 'HomePage.dart';
import 'Login.dart';
import 'Product_Preview.dart';
import 'Review_Gallary.dart';
import 'Review_Preview.dart';
import 'Search.dart';
import 'Seller_Details.dart';

class ProductDetail extends StatefulWidget {
  final Product? model;

  final int? secPos, index;
  final bool? list;

  const ProductDetail(
      {Key? key, this.model, this.secPos, this.index, this.list})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateItem();
}

List<User> reviewList = [];
List<imgModel> revImgList = [];
int offset = 0;
int total = 0;

class StateItem extends State<ProductDetail> with TickerProviderStateMixin {
  int _curSlider = 0;
  final _pageController = PageController(viewportFraction: 0.8);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int?> _selectedIndex = [];
  ChoiceChip? choiceChip, tagChip;
  int? _oldSelVarient = 0;
  bool _isProgress = false, _isLoading = true;
  var star1 = '0', star2 = '0', star3 = '0', star4 = '0', star5 = '0';
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int notificationoffset = 0;
  late int totalProduct = 0;

  // ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;
  List<Product> productList = [];
  late Animation<double> _progressAnimation;
  late AnimationController _progressAnimcontroller;

  var isDarkTheme;
  late ShortDynamicLink shortenedLink;
  String? shareLink;
  late String curPin;
  late double growStepWidth, beginWidth, endWidth = 0.0;
  TextEditingController qtyController = TextEditingController();
  var db = DatabaseHelper();
  List<String?> sliderList = [];

  @override
  void initState() {
    super.initState();
    sliderList.clear();

    sliderList.add(widget.model!.image);
    if (widget.model!.videType != null &&
        widget.model!.video != null &&
        widget.model!.video!.isNotEmpty &&
        widget.model!.video != '') {
      sliderList.add(widget.model!.image);
    }
    if (widget.model!.otherImage != null &&
        widget.model!.otherImage!.isNotEmpty) {
      sliderList.addAll(widget.model!.otherImage!);
    }

    for (int i = 0; i < widget.model!.prVarientList!.length; i++) {
      for (int j = 0; j < widget.model!.prVarientList![i].images!.length; j++) {
        sliderList.add(widget.model!.prVarientList![i].images![j]);
      }
    }

    revImgList.clear();
    if (widget.model!.reviewList!.isNotEmpty) {
      for (int i = 0;
          i < widget.model!.reviewList![0].productRating!.length;
          i++) {
        for (int j = 0;
            j < widget.model!.reviewList![0].productRating![i].imgList!.length;
            j++) {
          imgModel m = imgModel.fromJson(
              i, widget.model!.reviewList![0].productRating![i].imgList![j]);
          revImgList.add(m);
        }
      }
    }
    varientFun();
    getShare();

    _oldSelVarient = widget.model!.selVarient;

    reviewList.clear();
    offset = 0;
    total = 0;
    getReview();
    //getReviewImg();
    getDeliverable();
    notificationoffset = 0;

    getProduct();

    _progressAnimcontroller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _setProgressAnim(deviceWidth!, 1);
    //  notificationcontroller = ScrollController(keepScrollOffset: true);
    // notificationcontroller!.addListener(_transactionscrollListener);

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
  }

  _setProgressAnim(double maxWidth, int curPageIndex) {
    setState(() {
      growStepWidth = maxWidth / sliderList.length;
      beginWidth = growStepWidth * (curPageIndex - 1);
      endWidth = growStepWidth * curPageIndex;

      _progressAnimation = Tween<double>(begin: beginWidth, end: endWidth)
          .animate(_progressAnimcontroller);
    });

    _progressAnimcontroller.forward();
  }

  @override
  void dispose() {
    buttonController!.dispose();

    super.dispose();
  }

  Future<void> createDynamicLink() async {
    var documentDirectory;

    if (Platform.isIOS) {
      documentDirectory = (await getApplicationDocumentsDirectory()).path;
    } else {
      documentDirectory = (await getExternalStorageDirectory())!.path;
    }

    final response1 = await get(Uri.parse(widget.model!.image!));
    final bytes1 = response1.bodyBytes;

    final File imageFile = File('$documentDirectory/temp.png');

    imageFile.writeAsBytesSync(bytes1);
    Share.shareFiles([imageFile.path],
        text:
            '${widget.model!.name}\n${shortenedLink.shortUrl.toString()}\n$shareLink');
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

    return Scaffold(
      key: _scaffoldKey,
      body: _isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showContent(),
                showCircularProgress(_isProgress, colors.primary),
              ],
            )
          : noInternet(context),
    );
  }

  List<T?> map<T>(List list, Function handler) {
    List<T?> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget _slider() {
    double height = MediaQuery.of(context).size.height * .48;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
              // transitionDuration: Duration(seconds: 1),
              pageBuilder: (_, __, ___) => ProductPreview(
                pos: _curSlider,
                secPos: widget.secPos,
                index: widget.index,
                id: widget.model!.id,
                imgList: sliderList,
                list: widget.list,
                video: widget.model!.video,
                videoType: widget.model!.videType,
                from: true,
                screenSize: MediaQuery.of(context).size,
              ),
            ));
      },
      child: Stack(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
            /* height: height,
            width: double.infinity,*/
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sliderList.length,
              scrollDirection: Axis.horizontal,
              controller: _pageController,
              reverse: false,
              onPageChanged: (index) {
                /*   if (mounted)
                    setState(() {
                      _curSlider = index;
                    });*/
                //index i starts from 0!
                _curSlider = index;
                _progressAnimcontroller.reset(); //reset the animation first
                _setProgressAnim(deviceWidth!, index + 1);
                // context.read<ProductDetailProvider>().setCurSlider(index);
              },
              itemBuilder: (BuildContext context, int index) {
                return Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Hero(
                      tag: widget.list!
                          ? '${widget.index}${widget.model!.id}'
                          : '${widget.index}',
                      child: FadeInImage(
                        image: CachedNetworkImageProvider(sliderList[index]!),
                        placeholder: const AssetImage(
                          'assets/images/sliderph.png',
                        ),
                        /* height: height,
                        width: double.maxFinite,*/
                        fit: extendImg ? BoxFit.fill : BoxFit.fitWidth,

                        imageErrorBuilder: (context, error, stackTrace) =>
                            erroWidget(height),

                        //  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                      ),
                    ),
                    index == 1 ? playIcon() : Container()
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: <Widget>[
                      AnimatedProgressBar(
                        animation: _progressAnimation,
                      ),
                      Expanded(
                        child: Container(
                          height: 5.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white),
                        ),
                      )
                    ],
                  ))),
          favImg(),
          shareProduct(),
          indicatorImage(),
        ],
      ),
    );
  }

  Widget favImg() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      end: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: widget.model!.isFavLoading!
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 0.7,
                          )),
                    )
                  : Selector<FavoriteProvider, List<String?>>(
                      builder: (context, data, child) {
                        // print("object*****${data[0].id}***${widget.model!.id}");

                        return InkWell(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  !data.contains(widget.model!.id)
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  size: 20,
                                )),
                            onTap: () {
                              if (CUR_USERID != null) {
                                !data.contains(widget.model!.id)
                                    ? _setFav(-1)
                                    : _removeFav(-1);
                              } else {
                                if (!data.contains(widget.model!.id)) {
                                  widget.model!.isFavLoading = true;
                                  widget.model!.isFav = '1';
                                  context
                                      .read<FavoriteProvider>()
                                      .addFavItem(widget.model);
                                  db.addAndRemoveFav(widget.model!.id!, true);
                                  widget.model!.isFavLoading = false;
                                } else {
                                  widget.model!.isFavLoading = true;
                                  widget.model!.isFav = '0';
                                  context
                                      .read<FavoriteProvider>()
                                      .removeFavItem(
                                          widget.model!.prVarientList![0].id!);
                                  db.addAndRemoveFav(widget.model!.id!, false);
                                  widget.model!.isFavLoading = false;
                                }
                                setState(() {});
                              }
                            });
                      },
                      selector: (_, provider) => provider.favIdList,
                    )),
        ),
      ),
    );
  }

  Widget shareProduct() {
    return Positioned.directional(
        textDirection: Directionality.of(context),
        end: 0,
        bottom: 50,
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
                alignment: Alignment.bottomRight,
                child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: InkWell(
                        child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.share,
                              size: 20.0,
                            )),
                        onTap: createDynamicLink)))));
  }

  indicatorImage() {
    String? indicator = widget.model!.indicator;
    return Positioned.fill(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
          alignment: Alignment.bottomLeft,
          child: indicator == '1'
              ? SvgPicture.asset(
                  'assets/images/vag.svg',
                )
              : indicator == '2'
                  ? SvgPicture.asset(
                      'assets/images/nonvag.svg',
                    )
                  : Container()),
    ));
  }

  _rate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: <Widget>[
              RatingBarIndicator(
                rating: double.parse(widget.model!.rating!),
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 12.0,
                direction: Axis.horizontal,
              ),
              Text(
                ' ' + widget.model!.rating!,
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
              ),
              Text(
                ' | ' + widget.model!.noOfRating! + ' Ratings',
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: InkWell(
              onTap: () {
                if (context.read<ProductDetailProvider>().compareList.length >
                        0 &&
                    context
                        .read<ProductDetailProvider>()
                        .compareList
                        .contains(widget.model)) {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) =>
                              const CompareList()));
                } else {
                  context
                      .read<ProductDetailProvider>()
                      .addCompareList(widget.model!);

                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) =>
                              const CompareList()));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: colors.primary,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  getTranslated(context, 'GOTO_COMPARE')!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _price(pos, from) {
    double price = double.parse(widget.model!.prVarientList![pos].disPrice!);
    if (price == 0) {
      price = double.parse(widget.model!.prVarientList![pos].price!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getPriceFormat(context, price)!,
                //style: Theme.of(context).textTheme.headline6,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              from
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 3.0, bottom: 5, top: 3),
                      child: widget.model!.availability == '0'
                          ? Container()
                          : Row(
                              children: <Widget>[
                                GestureDetector(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.remove,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (_isProgress == false &&
                                        (int.parse(qtyController.text)) > 1) {
                                      // removeFromCart();
                                      addAndRemoveQty(qtyController.text, 2,
                                          widget.model!.itemsCounter!.length);
                                    }
                                  },
                                ),

                                //code for offline quantity
                                Container(
                                  width: 37,
                                  height: 20,
                                  color: Colors.transparent,
                                  child: Stack(
                                    children: [
                                      TextField(
                                        textAlign: TextAlign.center,
                                        readOnly: true,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor),
                                        controller: qtyController,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: '',
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          size: 1,
                                        ),
                                        onSelected: (String value) {
                                          if (context
                                                  .read<CartProvider>()
                                                  .isProgress ==
                                              false) {
                                            addAndRemoveQty(
                                                value,
                                                3,
                                                widget.model!.itemsCounter!
                                                    .length);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return widget.model!.itemsCounter!
                                              .map<PopupMenuItem<String>>(
                                                  (String value) {
                                            return PopupMenuItem(
                                                child: Text(value,
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor)),
                                                value: value);
                                          }).toList();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                GestureDetector(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (_isProgress == false) {
                                      addAndRemoveQty(qtyController.text, 1,
                                          widget.model!.itemsCounter!.length);
                                    }
                                  },
                                )
                              ],
                            ),
                    )
                  : Container(),
            ],
          ),
          _inclusiveTaxText(),
        ],
      ),
    );
  }

  removeFromCart() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }

        int qty;

        Product model = widget.model!;

        qty = (int.parse(qtyController.text) - int.parse(model.qtyStepSize!));

        if (qty < model.minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            var data = getdata['data'];

            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = ;

            context.read<UserProvider>().setCartCount(data['cart_count']);
            model.prVarientList![model.selVarient!].cartCount = qty.toString();

            var cart = getdata['cart'];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          setState(() {
            _isProgress = false;
          });
        });
      } else {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const Login()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _offPrice(pos) {
    double price = double.parse(widget.model!.prVarientList![pos].disPrice!);

    if (price != 0) {
      double off = (double.parse(widget.model!.prVarientList![pos].price!) -
              double.parse(widget.model!.prVarientList![pos].disPrice!))
          .toDouble();
      off = off * 100 / double.parse(widget.model!.prVarientList![pos].price!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: <Widget>[
            Text(
              getPriceFormat(context,
                  double.parse(widget.model!.prVarientList![pos].price!))!,
              style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  decoration: TextDecoration.lineThrough, letterSpacing: 0),
            ),
            Text(' | ' + off.toStringAsFixed(2) + '% off',
                style: Theme.of(context)
                    .textTheme
                    .overline!
                    .copyWith(color: colors.primary, letterSpacing: 0)),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
        widget.model!.name!,
        style: Theme.of(context)
            .textTheme
            .subtitle1!
            .copyWith(color: Theme.of(context).colorScheme.lightBlack),
      ),
    );
  }

  Widget _inclusiveTaxText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "${getTranslated(context, "Inclusive of all taxes")}",
        style: Theme.of(context).textTheme.subtitle1!.copyWith(
            color: Theme.of(context).colorScheme.lightBlack2, fontSize: 12),
      ),
    );
  }

  _desc() {
    return widget.model!.desc!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: WebView(
                  gestureRecognizers: gestureRecognizers,
                  backgroundColor: Theme.of(context).colorScheme.lightWhite,
                  zoomEnabled: true,
                  javascriptMode: JavascriptMode.unrestricted,
                  initialUrl: 'about:blank',
                  onWebViewCreated: (WebViewController webViewController) {
                    webViewController.loadHtmlString(widget.model!.desc!);
                  }),
            ),
          )
        : Container();
  }

  _getVarient(int? pos) {
    if (widget.model!.type == 'variable_product') {
      List att = [], val = [];
      if (widget.model!.prVarientList![widget.model!.selVarient!].attr_name !=
          null) {
        att = widget.model!.prVarientList![widget.model!.selVarient!].attr_name!
            .split(',');
        val = widget
            .model!.prVarientList![widget.model!.selVarient!].varient_value!
            .split(',');
      }
      return widget.model!.prVarientList![widget.model!.selVarient!]
                      .attr_name !=
                  null &&
              widget.model!.prVarientList![widget.model!.selVarient!].attr_name!
                  .isNotEmpty
          ? InkWell(
              child: MediaQuery.removePadding(
                removeTop: true,
                context: context,
                child: Card(
                  elevation: 0,
                  child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: att.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            dense: true,
                            trailing: const Icon(Icons.keyboard_arrow_right),
                            title: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                                  .fontColor),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 5.0),
                                    child: Text(
                                      val[index],
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]));
                      }),
                ),
              ),
              onTap: _chooseVarient,
            )
          : Container();
    } else {
      return Container();
    }
  }

  void _pincodeCheck() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close),
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                validator: (val) => validatePincode(val!,
                                    getTranslated(context, 'PIN_REQUIRED')),
                                onSaved: (String? value) {
                                  if (value != null) curPin = value;
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.location_on),
                                  hintText:
                                      getTranslated(context, 'PINCODEHINT_LBL'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SimBtn(
                                    size: 1.0,
                                    title: getTranslated(context, 'APPLY'),
                                    onBtnSelected: () async {
                                      if (validateAndSave()) {
                                        validatePin(curPin, false);
                                      }
                                    }),
                              ),
                            ],
                          )),
                    ))
              ]),
            );
            //});
          });
        });
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  void _extraDetail() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    child: SingleChildScrollView(
                      child: _desc(),
                    ),
                  ),
                  widget.model!.desc!.isNotEmpty
                      ? const Divider()
                      : Container(),
                  _attr(),
                  widget.model!.attributeList!.isNotEmpty
                      ? const Divider()
                      : Container(),
                  _madeIn(),
                  _warrenty(),
                  _gaurantee(),
                  _otherDetail(widget.model!.selVarient),
                  _cancleable(),
                ],
              )),
            );
            //});
          });
        });
  }

  void _chooseVarient() {
    bool? available, outOfStock;
    int? selectIndex = 0;
    _selectedIndex.clear();
    if (widget.model!.stockType == '0' || widget.model!.stockType == '1') {
      if (widget.model!.availability == '1') {
        available = true;
        outOfStock = false;
        _oldSelVarient = widget.model!.selVarient;
      } else {
        available = false;
        outOfStock = true;
      }
    } else if (widget.model!.stockType == '') {
      available = true;
      outOfStock = false;
      _oldSelVarient = widget.model!.selVarient;
    } else if (widget.model!.stockType == '2') {
      if (widget
              .model!.prVarientList![widget.model!.selVarient!].availability ==
          '1') {
        available = true;
        outOfStock = false;
        _oldSelVarient = widget.model!.selVarient;
      } else {
        available = false;
        outOfStock = true;
      }
    }

    List<String> selList = widget
        .model!.prVarientList![widget.model!.selVarient!].attribute_value_ids!
        .split(',');

    for (int i = 0; i < widget.model!.attributeList!.length; i++) {
      List<String> sinList = widget.model!.attributeList![i].id!.split(',');

      for (int j = 0; j < sinList.length; j++) {
        if (selList.contains(sinList[j])) {
          _selectedIndex.insert(i, j);
        }
      }

      if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      getTranslated(context, 'selectVarient')!,
                      //   style: Theme.of(context).textTheme.headline6,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Divider(),
                  _title(),
                  available! || outOfStock!
                      ? _price(selectIndex, false)
                      : Container(),
                  available! || outOfStock!
                      ? _offPrice(_oldSelVarient)
                      : Container(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.model!.attributeList!.length,
                    itemBuilder: (context, index) {
                      List<Widget?> chips = [];
                      List<String> att =
                          widget.model!.attributeList![index].value!.split(',');
                      List<String> attId =
                          widget.model!.attributeList![index].id!.split(',');
                      List<String> attSType =
                          widget.model!.attributeList![index].sType!.split(',');

                      List<String> attSValue = widget
                          .model!.attributeList![index].sValue!
                          .split(',');

                      int? varSelected;

                      List<String> wholeAtt = widget.model!.attrIds!.split(',');
                      for (int i = 0; i < att.length; i++) {
                        Widget itemLabel;
                        if (attSType[i] == '1') {
                          String clr = (attSValue[i].substring(1));

                          String color = '0xff' + clr;

                          itemLabel = Container(
                            width: 25,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(int.parse(color))),
                          );
                        } else if (attSType[i] == '2') {
                          itemLabel = ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(attSValue[i],
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) =>
                                      erroWidget(80)));
                        } else {
                          itemLabel = Text(att[i],
                              style: TextStyle(
                                  color: _selectedIndex[index] == (i)
                                      ? Theme.of(context).colorScheme.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .fontColor));
                        }

                        if (_selectedIndex[index] != null &&
                            wholeAtt.contains(attId[i])) {
                          choiceChip = ChoiceChip(
                            selected: _selectedIndex.length > index
                                ? _selectedIndex[index] == i
                                : false,
                            label: itemLabel,
                            selectedColor: colors.primary,
                            backgroundColor:
                                Theme.of(context).colorScheme.white,
                            labelPadding: const EdgeInsets.all(0),
                            //selectedColor: Theme.of(context).colorScheme.fontColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  attSType[i] == '1' ? 100 : 10),
                              side: BorderSide(
                                  color: _selectedIndex[index] == (i)
                                      ? colors.primary
                                      : colors.black12,
                                  width: 1.5),
                            ),
                            onSelected: att.length == 1
                                ? null
                                : (bool selected) {
                                    if (mounted) {
                                      setState(() {
                                        available = false;
                                        _selectedIndex[index] =
                                            selected ? i : null;
                                        List<int> selectedId =
                                            []; //list where user choosen item id is stored
                                        List<bool> check = [];
                                        for (int i = 0;
                                            i <
                                                widget.model!.attributeList!
                                                    .length;
                                            i++) {
                                          List<String> attId = widget
                                              .model!.attributeList![i].id!
                                              .split(',');

                                          if (_selectedIndex[i] != null) {
                                            selectedId.add(int.parse(
                                                attId[_selectedIndex[i]!]));
                                          }
                                        }
                                        check.clear();
                                        late List<String> sinId;
                                        findMatch:
                                        for (int i = 0;
                                            i <
                                                widget.model!.prVarientList!
                                                    .length;
                                            i++) {
                                          sinId = widget
                                              .model!
                                              .prVarientList![i]
                                              .attribute_value_ids!
                                              .split(',');

                                          for (int j = 0;
                                              j < selectedId.length;
                                              j++) {
                                            if (sinId.contains(
                                                selectedId[j].toString())) {
                                              check.add(true);

                                              if (selectedId.length ==
                                                      sinId.length &&
                                                  check.length ==
                                                      selectedId.length) {
                                                varSelected = i;
                                                selectIndex = i;
                                                break findMatch;
                                              }
                                            } else {
                                              check.clear();
                                              selectIndex = null;
                                              break;
                                            }
                                          }
                                        }

                                        if (selectedId.length == sinId.length &&
                                            check.length == selectedId.length) {
                                          if (widget.model!.stockType == '0' ||
                                              widget.model!.stockType == '1') {
                                            if (widget.model!.availability ==
                                                '1') {
                                              available = true;
                                              outOfStock = false;
                                              _oldSelVarient = varSelected;
                                            } else {
                                              available = false;
                                              outOfStock = true;
                                            }
                                          } else if (widget.model!.stockType ==
                                              '') {
                                            available = true;
                                            outOfStock = false;
                                            _oldSelVarient = varSelected;
                                          } else if (widget.model!.stockType ==
                                              '2') {
                                            if (widget
                                                    .model!
                                                    .prVarientList![
                                                        varSelected!]
                                                    .availability ==
                                                '1') {
                                              available = true;
                                              outOfStock = false;
                                              _oldSelVarient = varSelected;
                                            } else {
                                              available = false;
                                              outOfStock = true;
                                            }
                                          }
                                        } else {
                                          available = false;
                                          outOfStock = false;
                                        }
                                        if (widget
                                            .model!
                                            .prVarientList![_oldSelVarient!]
                                            .images!
                                            .isNotEmpty) {
                                          int oldVarTotal = 0;
                                          if (_oldSelVarient! > 0) {
                                            for (int i = 0;
                                                i < _oldSelVarient!;
                                                i++) {
                                              oldVarTotal = oldVarTotal +
                                                  widget
                                                      .model!
                                                      .prVarientList![i]
                                                      .images!
                                                      .length;
                                            }
                                          }
                                          int p =
                                              widget.model!.otherImage!.length +
                                                  1 +
                                                  oldVarTotal;

                                          _pageController.jumpToPage(p);
                                        }
                                      });
                                    }
                                  },
                          );

                          chips.add(choiceChip);
                        }
                      }

                      String value = _selectedIndex[index] != null &&
                              _selectedIndex[index]! <= att.length
                          ? att[_selectedIndex[index]!]
                          : getTranslated(context, 'VAR_SEL')!.substring(
                              2, getTranslated(context, 'VAR_SEL')!.length);
                      return chips.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.model!.attributeList![index].name! +
                                        ' : ' +
                                        value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Wrap(
                                    children: chips.map<Widget>((Widget? chip) {
                                      return Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: chip,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            )
                          : Container();
                    },
                  ),
                  available == false || outOfStock == true
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            outOfStock == true
                                ? 'Out of Stock'
                                : "This varient doesn't available.",
                            style: const TextStyle(color: colors.red),
                          ),
                        ))
                      : Container(),
                  CupertinoButton(
                    padding: const EdgeInsets.all(0),
                    child: Container(
                        alignment: FractionalOffset.center,
                        height: 55,
                        decoration: BoxDecoration(
                          color: available!
                              ? colors.primary
                              : Theme.of(context).colorScheme.gray,
                        ),
                        child: Text(getTranslated(context, 'APPLY')!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  color: colors.whiteTemp,
                                ))),
                    onPressed: available! ? applyVarient : null,
                  )
                ],
              ),
            );
          });
        });
  }

  applyVarient() {
    Navigator.of(context).pop();

    if (mounted) {
      setState(() {
        widget.model!.selVarient = _oldSelVarient;
      });
    }
  }

  Future<void> addToCart(
      String qty, bool intent, bool from, Product product) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        try {
          if (mounted) {
            setState(() {
              _isProgress = true;
            });
          }

          Product model = widget.model!;

          if (int.parse(qty) < model.minOrderQuntity!) {
            qty = model.minOrderQuntity.toString();
            setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
          }

          var parameter = {
            USER_ID: CUR_USERID,
            PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
            QTY: qty,
          };

          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(const Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            var data = getdata['data'];

            context.read<UserProvider>().setCartCount(data['cart_count']);

            widget.model!.prVarientList![widget.model!.selVarient!].cartCount =
                qty.toString();

            var cart = getdata['cart'];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => SectionModel.fromCart(cart))
                .toList();

            context.read<CartProvider>().setCartlist(cartList);

            if (intent) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const Cart(
                    fromBottom: false,
                  ),
                ),
              );
            }
          } else {
            setSnackbar(msg!, context);
          }
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        }
      } else {
        db.insertCart(
            widget.model!.id!,
            widget.model!.prVarientList![widget.model!.selVarient!].id!,
            qty,
            context);
        Future.delayed(const Duration(milliseconds: 100)).then((_) async {
          if (from && intent) {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const Cart(
                  fromBottom: false,
                ),
              ),
            );
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> getReview() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_ID: widget.model!.id,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        Response response =
            await post(getRatingApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          total = int.parse(getdata['total']);

          star1 = getdata['star_1'];
          star2 = getdata['star_2'];
          star3 = getdata['star_3'];
          star4 = getdata['star_4'];
          star5 = getdata['star_5'];
          if ((offset) < total) {
            var data = getdata['data'];
            reviewList =
                (data as List).map((data) => User.forReview(data)).toList();

            offset = offset + perPage;
          }
        } else {
          if (msg != 'No ratings found !') setSnackbar(msg!, context);
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _setFav(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            index == -1
                ? widget.model!.isFavLoading = true
                : productList[index].isFavLoading = true;
          });
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model!.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          index == -1
              ? widget.model!.isFav = '1'
              : productList[index].isFav = '1';

          context.read<FavoriteProvider>().addFavItem(widget.model);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted) {
          setState(() {
            index == -1
                ? widget.model!.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _removeFav(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            index == -1
                ? widget.model!.isFavLoading = true
                : productList[index].isFavLoading = true;
          });
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model!.id};
        Response response =
            await post(removeFavApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          index == -1
              ? widget.model!.isFav = '0'
              : productList[index].isFav = '0';
          context
              .read<FavoriteProvider>()
              .removeFavItem(widget.model!.prVarientList![0].id!);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted) {
          setState(() {
            index == -1
                ? widget.model!.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _showContent() {
    return Column(children: <Widget>[
      Expanded(
          child: CustomScrollView(slivers: <Widget>[
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * .43,
          floating: false,
          pinned: false,
          backgroundColor: Theme.of(context).colorScheme.white,
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              //decoration: shadow(),
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
          actions: [
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
            IconButton(
              icon: SvgPicture.asset(
                imagePath + 'desel_fav.svg',
                height: 20,
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
            Selector<UserProvider, String>(
              builder: (context, data, child) {
                return IconButton(
                  icon: Stack(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          imagePath + 'appbarCart.svg',
                          color: colors.primary,
                        ),
                      ),
                      (data.isNotEmpty && data != '0')
                          ? Positioned(
                              bottom: 20,
                              right: 0,
                              child: Container(
                                //  height: 20,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary),
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
          flexibleSpace: FlexibleSpaceBar(
            background: _slider(),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _title(),
                          _rate(),
                          _price(widget.model!.selVarient, true),
                          _offPrice(widget.model!.selVarient),
                          _shortDesc(),
                        ],
                      ),
                    ),
                    _getVarient(widget.model!.selVarient),
                    _specification(),
                    _deliverPincode(),
                    _sellerDetail(),
                  ],
                ),
                reviewList.isNotEmpty
                    ? Card(
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _reviewTitle(),
                            _reviewStar(),
                            _reviewImg(),
                            _review(),
                          ],
                        ),
                      )
                    : Container(),
                // reviewList.length > 0 ? Divider() : Container(),
                productList.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          getTranslated(context, 'MORE_PRODUCT')!,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                        ),
                      )
                    : Container(),
                Container(
                    height: 230,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                            getProduct();
                          }
                          return true;
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          //controller: _controller,
                          itemCount: (notificationoffset < totalProduct)
                              ? productList.length + 1
                              : productList.length,
                          itemBuilder: (context, index) {
                            return (index == productList.length &&
                                    !notificationisloadmore)
                                ? simmerSingle()
                                : productItem(index);
                          },
                        ))),
              ],
            )
          ]),
        )
      ])),
      widget.model!.availability == '1' || widget.model!.stockType == ''
          ? Container(
              height: 55,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.black26,
                      blurRadius: 10)
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: deviceWidth! * 0.5,
                        child: InkWell(
                          onTap: () {
                            String qty;

                            qty = qtyController.text;

                            addToCart(qty, false, true, widget.model!);
                          },
                          child: Center(
                              child: Text(
                            getTranslated(context, 'ADD_CART')!,
                            style: Theme.of(context).textTheme.button!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary),
                          )),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.btnColor),
                            onPressed: () {
                              String qty;

                              qty = qtyController.text;

                              addToCart(qty, true, true, widget.model!);
                            },
                            icon: Icon(
                              Icons.shopping_bag,
                              color: Theme.of(context).colorScheme.white,
                            ),
                            label: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                getTranslated(context, 'BUYNOW')!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: true,
                              ),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Container(
              height: 55,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.black26,
                      blurRadius: 10)
                ],
              ),
              child: Center(
                  child: Text(
                getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                style: Theme.of(context)
                    .textTheme
                    .button!
                    .copyWith(fontWeight: FontWeight.bold, color: Colors.red),
              )),
            ),
    ]);
  }

  simmerSingle() {
    return Container(
        //width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Container(
            width: deviceWidth! * 0.45,
            height: 250,
            color: Theme.of(context).colorScheme.white,
          ),
        ));
  }

  _madeIn() {
    String? madeIn = widget.model!.madein;

    return madeIn != null && madeIn.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(madeIn),
              dense: true,
              title: Text(
                getTranslated(context, 'MADE_IN')!,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  Widget productItem(int index) {
    if (index < productList.length) {
      String? offPer;
      double price =
          double.parse(productList[index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(productList[index].prVarientList![0].price!);
      } else {
        double off =
            double.parse(productList[index].prVarientList![0].price!) - price;
        offPer = ((off * 100) /
                double.parse(productList[index].prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.45;

      return SizedBox(
          height: 250,
          width: width,
          child: Card(
            elevation: 0.2,
            margin: const EdgeInsetsDirectional.only(bottom: 5, end: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)),
                          child: Hero(
                            tag: '$index${productList[index].id}',
                            child: FadeInImage(
                              image: CachedNetworkImageProvider(
                                  productList[index].image!),
                              height: double.maxFinite,
                              width: double.maxFinite,
                              fit: extendImg ? BoxFit.fill : BoxFit.contain,
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  erroWidget(
                                double.maxFinite,
                              ),

                              //errorWidget: (context, url, e) => placeHolder(width),
                              placeholder: placeHolder(
                                double.maxFinite,
                              ),
                            ),
                          ),
                        ),
                        offPer != null
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      offPer + '%',
                                      style: const TextStyle(
                                          color: colors.whiteTemp,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9),
                                    ),
                                  ),
                                  margin: const EdgeInsets.all(5),
                                ),
                              )
                            : Container(),
                        const Divider(
                          height: 1,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 5.0,
                      top: 5,
                    ),
                    child: Row(
                      children: [
                        RatingBarIndicator(
                          rating: double.parse(productList[index].rating!),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star_rate_rounded,
                            color: Colors.amber,
                            //color: colors.primary,
                          ),
                          unratedColor: Colors.grey.withOpacity(0.5),
                          itemCount: 5,
                          itemSize: 12.0,
                          direction: Axis.horizontal,
                          itemPadding: const EdgeInsets.all(0),
                        ),
                        Text(
                          ' (' + productList[index].noOfRating! + ')',
                          style: Theme.of(context).textTheme.overline,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 5.0, top: 5, bottom: 5),
                    child: Text(
                      productList[index].name!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text(getPriceFormat(context, price)!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold)),
                      Text(
                        double.parse(productList[index]
                                    .prVarientList![0]
                                    .disPrice!) !=
                                0
                            ? getPriceFormat(
                                context,
                                double.parse(productList[index]
                                    .prVarientList![0]
                                    .price!))!
                            : '',
                        style: Theme.of(context).textTheme.overline!.copyWith(
                            decoration: TextDecoration.lineThrough,
                            letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                Product model = productList[index];
                notificationoffset = 0;

                Navigator.push(
                  context,
                  PageRouteBuilder(
                      // transitionDuration: Duration(seconds: 1),
                      pageBuilder: (_, __, ___) => ProductDetail(
                          model: model,
                          secPos: widget.secPos,
                          index: index,
                          list: true
                          //  title: sectionList[secPos].title,
                          )),
                ).then((value) {
                  setState(() {});
                });
              },
            ),
          ));
    } else {
      return Container();
    }
  }

  Widget _review() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            itemCount: reviewList.length >= 2 ? 2 : reviewList.length,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (context, index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reviewList[index].username!,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                      const Spacer(),
                      Text(
                        reviewList[index].date!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontSize: 11),
                      )
                    ],
                  ),
                  RatingBarIndicator(
                    rating: double.parse(reviewList[index].rating!),
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                  ),
                  reviewList[index].comment != null &&
                          reviewList[index].comment!.isNotEmpty
                      ? Text(
                          reviewList[index].comment ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Container(),
                  reviewImage(index),
                ],
              );
            });
  }

  Future getProduct() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          if (mounted) {
            setState(() {
              notificationisloadmore = false;
              notificationisgettingdata = true;
              if (notificationoffset == 0) {
                productList = [];
              }
            });
          }

          var parameter = {
            CATID: widget.model!.categoryId,
            LIMIT: perPage.toString(),
            OFFSET: notificationoffset.toString(),
            ID: widget.model!.id,
            IS_SIMILAR: '1'
          };

          if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

          Response response =
              await post(getProductApi, headers: headers, body: parameter)
                  .timeout(const Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          bool error = getdata['error'];
          // String msg = getdata["message"];

          notificationisgettingdata = false;
          if (notificationoffset == 0) notificationisnodata = error;

          if (!error) {
            totalProduct = int.parse(getdata['total']);
            if (mounted) {
              Future.delayed(
                  Duration.zero,
                  () => setState(() {
                        List mainlist = getdata['data'];

                        if (mainlist.isNotEmpty) {
                          List<Product> items = [];
                          List<Product> allitems = [];

                          items.addAll(mainlist
                              .map((data) => Product.fromJson(data))
                              .toList());

                          allitems.addAll(items);

                          for (Product item in items) {
                            productList
                                .where((i) => i.id == item.id)
                                .map((obj) {
                              allitems.remove(item);
                              return obj;
                            }).toList();
                          }
                          productList.addAll(allitems);
                          notificationisloadmore = true;
                          notificationoffset = notificationoffset + perPage;
                        } else {
                          notificationisloadmore = false;
                        }
                      }));
            }
          } else {
            notificationisloadmore = false;
            if (mounted) if (mounted) setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            notificationisloadmore = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _otherDetail(int? pos) {
    String? returnable = widget.model!.isReturnable;
    if (returnable == '1') {
      returnable = RETURN_DAYS! + ' Days';
    } else {
      returnable = 'No';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        trailing: Text(returnable),
        dense: true,
        title: Text(
          getTranslated(context, 'RETURNABLE')!,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ),
    );
  }

  _cancleable() {
    String? cancleable = widget.model!.isCancelable;
    if (cancleable == '1') {
      cancleable = 'Till ' + widget.model!.cancleTill!;
    } else {
      cancleable = 'No';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        trailing: Text(cancleable),
        dense: true,
        title: Text(
          getTranslated(context, 'CANCELLABLE')!,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ),
    );
  }

  _specification() {
    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text(
            getTranslated(context, 'SPECIFICATION')!,
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right),
        ),
        onTap: _extraDetail,
      ),
    );
  }

  _sellerDetail() {
    String? name = widget.model!.seller_name;
    name ??= ' ';

    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text(
            getTranslated(context, 'SOLD_BY')! + ' : ' + name,
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => SellerProfile(
                      sellerStoreName: widget.model!.store_name ?? '',
                      sellerRating: widget.model!.seller_rating ?? '',
                      sellerImage: widget.model!.seller_profile ?? '',
                      sellerName: widget.model!.seller_name ?? '',
                      sellerID: widget.model!.seller_id,
                      storeDesc: widget.model!.store_description,
                    )));
          },
        ),
      ),
    );
  }

  _deliverPincode() {
    String pin = context.read<UserProvider>().curPincode;
    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text(
            pin == ''
                ? getTranslated(context, 'SELOC')!
                : getTranslated(context, 'DELIVERTO')! + pin,
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right),
        ),
        onTap: _pincodeCheck,
      ),
    );
  }

  _reviewTitle() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children: [
            Text(
              getTranslated(context, 'CUSTOMER_REVIEW_LBL')!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  getTranslated(context, 'VIEW_ALL')!,
                  style: const TextStyle(color: colors.primary),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) =>
                          ReviewList(widget.model!.id, widget.model)),
                );
              },
            )
          ],
        ));
  }

  reviewImage(int i) {
    return SizedBox(
      height: reviewList[i].imgList!.isNotEmpty ? 50 : 0,
      child: ListView.builder(
        itemCount: reviewList[i].imgList!.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, bottom: 5.0, top: 5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: widget.secPos,
                        index: widget.index,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                      ),
                    ));
              },
              child: Hero(
                tag: '$index${reviewList[i].id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: FadeInImage(
                    image: CachedNetworkImageProvider(
                        reviewList[i].imgList![index]),
                    height: 50.0,
                    width: 50.0,
                    placeholder: placeHolder(50),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _shortDesc() {
    return widget.model!.shortDescription != null &&
            widget.model!.shortDescription!.isNotEmpty
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5),
            child: Text(
              widget.model!.shortDescription!,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          )
        : Container();
  }

  _attr() {
    return widget.model!.attributeList!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.model!.attributeList!.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          widget.model!.attributeList![i].name!,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                      Expanded(
                          flex: 2,
                          child: Text(
                            widget.model!.attributeList![i].value!,
                            textAlign: TextAlign.right,
                          )),
                    ],
                  ),
                );
              },
            ),
          )
        : Container();
  }

  Future<void> getShare() async {
    shortenedLink = await FirebaseDynamicLinks.instance
        .buildShortLink(DynamicLinkParameters(
      link: Uri.parse(
          'https://$deepLinkName/?index=${widget.index}&secPos=${widget.secPos}&list=${widget.list}&id=${widget.model!.id}'),
      uriPrefix: deepLinkUrlPrefix,
      androidParameters: const AndroidParameters(
        packageName: packageName,
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: iosPackage,
        minimumVersion: '1',
        appStoreId: appStoreId,
      ),
    ));

    Future.delayed(Duration.zero, () {
      shareLink =
          "\n$appName\n${getTranslated(context, 'APPFIND')}$androidLink";
    });
  }

  _warrenty() {
    String? warranty = widget.model!.warranty;

    return warranty != null && warranty.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(warranty),
              dense: true,
              title: Text(
                getTranslated(context, 'WARRENTY')!,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  playIcon() {
    return Align(
        alignment: Alignment.center,
        child: (widget.model!.videType != null &&
                widget.model!.video != null &&
                widget.model!.video!.isNotEmpty &&
                widget.model!.video != '')
            ? const Icon(
                Icons.play_circle_fill_outlined,
                color: colors.primary,
                size: 35,
              )
            : Container());
  }

  _reviewImg() {
    return revImgList.isNotEmpty
        ? SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: revImgList.length > 5 ? 5 : revImgList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: GestureDetector(
                    onTap: () async {
                      if (index == 4) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) =>
                                    ReviewGallary(productModel: widget.model)));
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                // transitionDuration: Duration(seconds: 1),
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      productModel: widget.model,
                                    )));
                      }
                    },
                    child: Stack(
                      children: [
                        FadeInImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          image: CachedNetworkImageProvider(
                            revImgList[index].img!,
                          ),
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
                                  '+${revImgList.length - 5}',
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
          )
        : Container();
  }

  _gaurantee() {
    String? gaurantee = widget.model!.gurantee;

    return gaurantee != null && gaurantee.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(gaurantee),
              dense: true,
              title: Text(
                getTranslated(context, 'GAURANTEE')!,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  Future<void> validatePin(String pin, bool first) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ZIPCODE: pin,
          PRODUCT_ID: widget.model!.id,
        };

        Response response =
            await post(checkDeliverableApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata['error'];
        String? msg = getdata['message'];

        if (error) {
          curPin = '';
        } else {
          if (pin != context.read<UserProvider>().curPincode) {
            context.read<HomeProvider>().setSecLoading(true);
            getSection();
          }
          context.read<UserProvider>().setPincode(pin);
        }
        if (!first) {
          Navigator.pop(context);
          setSnackbar(msg!, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void getSection() {
    Map parameter = {PRODUCT_LIMIT: '6', PRODUCT_OFFSET: '0'};

    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
    String curPin = context.read<UserProvider>().curPincode;
    if (curPin != '') parameter[ZIPCODE] = curPin;

    apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
      bool error = getdata['error'];
      String? msg = getdata['message'];
      sectionList.clear();
      if (!error) {
        var data = getdata['data'];

        sectionList =
            (data as List).map((data) => SectionModel.fromJson(data)).toList();
      } else {
        if (curPin != '') context.read<UserProvider>().setPincode('');
        setSnackbar(
          msg!,
          context,
        );
      }

      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  Future<void> getDeliverable() async {
    String pin = context.read<UserProvider>().curPincode;
    if (pin != '') {
      validatePin(pin, true);
    }
  }

  _reviewStar() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                widget.model!.rating ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              Text(
                  "${reviewList.length}  ${getTranslated(context, "RATINGS")!}")
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getRatingBarIndicator(5.0, 5),
                getRatingBarIndicator(4.0, 4),
                getRatingBarIndicator(3.0, 3),
                getRatingBarIndicator(2.0, 2),
                getRatingBarIndicator(1.0, 1),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getRatingIndicator(int.parse(star5)),
                getRatingIndicator(int.parse(star4)),
                getRatingIndicator(int.parse(star3)),
                getRatingIndicator(int.parse(star2)),
                getRatingIndicator(int.parse(star1)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getTotalStarRating(star5),
              getTotalStarRating(star4),
              getTotalStarRating(star3),
              getTotalStarRating(star2),
              getTotalStarRating(star1),
            ],
          ),
        ),
      ],
    );
  }

  getRatingIndicator(var totalStar) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Stack(
        children: [
          Container(
            height: 10,
            width: MediaQuery.of(context).size.width / 3,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3.0),
                border: Border.all(
                  width: 0.5,
                  color: colors.grad2Color,
                )),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: colors.primary,
            ),
            width: (totalStar / reviewList.length) *
                MediaQuery.of(context).size.width /
                3,
            height: 10,
          ),
        ],
      ),
    );
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        textDirection: TextDirection.rtl,
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_rate_rounded,
          color: Colors.amber,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }

  getTotalStarRating(var totalStar) {
    return SizedBox(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ));
  }

  varientFun() async {
    if (CUR_USERID != null) {
      if (widget.model!.prVarientList![widget.model!.selVarient!].cartCount! !=
          '0') {
        qtyController.text =
            widget.model!.prVarientList![widget.model!.selVarient!].cartCount!;
      } else {
        qtyController.text = widget.model!.minOrderQuntity.toString();
      }
    } else {
      String qty = (await db.checkCartItemExists(widget.model!.id!,
          widget.model!.prVarientList![widget.model!.selVarient!].id!))!;
      if (qty == '0') {
        qtyController.text = widget.model!.minOrderQuntity.toString();
      } else {
        widget.model!.prVarientList![widget.model!.selVarient!].cartCount = qty;
        qtyController.text = qty;
      }
    }

    setState(() {});
  }

  addAndRemoveQty(String qty, int from, int totalLen) {
    Product model = widget.model!;

    if (CUR_USERID != null || CUR_USERID != '') {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + (1)).toString();
        }
      } else if (from == 2) {
        if (int.parse(qty) < model.minOrderQuntity!) {
          qtyController.text = '1';
        } else {
          qtyController.text = (int.parse(qty) - 1).toString();
        }
      } else {
        qtyController.text = qty;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    } else {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          db.updateCart(model.id!, model.prVarientList![model.selVarient!].id!,
              (int.parse(qty) + 1).toString());
        }
      } else if (from == 2) {
        if (int.parse(qty) < model.minOrderQuntity!) {
          db.updateCart(
              model.id!, model.prVarientList![model.selVarient!].id!, '1');
        } else {
          db.updateCart(model.id!, model.prVarientList![model.selVarient!].id!,
              (int.parse(qty) - 1).toString());
        }
      } else {
        db.updateCart(
            model.id!, model.prVarientList![model.selVarient!].id!, qty);
      }
      context.read<CartProvider>().setProgress(false);
    }
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  final Animation<double> animation;

  const AnimatedProgressBar({Key? key, required this.animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    // final Animation<double> animation = animation;
    return Container(
      height: 5.0,
      width: animation.value,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.black),
    );
  }
}
