import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/AppBtn.dart';
import 'package:eshop_multivendor/Helper/SimBtn.dart';
import 'package:eshop_multivendor/Helper/SqliteData.dart';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/FavoriteProvider.dart';
import 'package:eshop_multivendor/Provider/ProductDetailProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import 'HomePage.dart';
import 'Product_Detail.dart';

class ProductList extends StatefulWidget {
  final String? name, id;
  final bool? tag, fromSeller;
  final int? dis;

  const ProductList(
      {Key? key, this.id, this.name, this.tag, this.fromSeller, this.dis})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProduct();
}

class StateProduct extends State<ProductList> with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  String sortBy = 'p.id', orderBy = 'DESC';
  int offset = 0;
  int total = 0;
  String? totalProduct;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  var filterList;
  String minPrice = '0', maxPrice = '0';
  List<String>? attnameList;
  List<String>? attsubList;
  List<String>? attListId;
  bool _isNetworkAvail = true;
  List<String> selectedId = [];
  bool _isFirstLoad = true;

  String selId = '';
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  //bool listType = true;
  final List<TextEditingController> _controller = [];
  List<String>? tagList = [];
  ChoiceChip? tagChip, choiceChip;
  RangeValues? _currentRangeValues;
  var db = DatabaseHelper();

  late AnimationController listViewIconController;

  // late UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getProduct('0');

    listViewIconController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
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

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            if (offset < total) getProduct('0');
          });
        }
      }
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    listViewIconController.dispose();
    controller.removeListener(() {});
    for (int i = 0; i < _controller.length; i++) {
      _controller[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  @override
  Widget build(BuildContext context) {
    // userProvider = Provider.of<UserProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        context.read<ProductDetailProvider>().setListType(false);
        return true;
      },
      child: Scaffold(
          appBar: widget.fromSeller! ? null : getAppBar(widget.name!, context),
          key: _scaffoldKey,
          body: _isNetworkAvail
              ? _isLoading
                  ? shimmer(context)
                  : Stack(
                      children: <Widget>[
                        _showForm(context),
                        showCircularProgress(_isProgress, colors.primary),
                      ],
                    )
              : noInternet(context)),
    );
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
                  offset = 0;
                  total = 0;
                  getProduct('0');
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

  noIntBtn(BuildContext context) {
    double width = deviceWidth!;
    return Container(
        padding: const EdgeInsetsDirectional.only(bottom: 10.0, top: 50.0),
        child: Center(
            child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: colors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80.0)),
          ),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (BuildContext context) => super.widget));
          },
          child: Ink(
            child: Container(
              constraints: BoxConstraints(maxWidth: width / 1.2, minHeight: 45),
              alignment: Alignment.center,
              child: Text(getTranslated(context, 'TRY_AGAIN_INT_LBL')!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Theme.of(context).colorScheme.white,
                      fontWeight: FontWeight.normal)),
            ),
          ),
        )));
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      Product model = productList[index];
      return FutureBuilder(
          future: db.checkCartItemExists(
              model.id!, model.prVarientList![model.selVarient!].id!),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              totalProduct = model.total;

              if (_controller.length < index + 1) {
                _controller.add(TextEditingController());
              }

              if (CUR_USERID == null) {
                model.prVarientList![model.selVarient!].cartCount =
                    snapshot.data;
                _controller[index].text = snapshot.data;
              } else {
                _controller[index].text =
                    model.prVarientList![model.selVarient!].cartCount!;
              }

              List att = [], val = [];
              if (model.prVarientList![model.selVarient!].attr_name != '') {
                att = model.prVarientList![model.selVarient!].attr_name!
                    .split(',');
                val = model.prVarientList![model.selVarient!].varient_value!
                    .split(',');
              }

              double price = double.parse(
                  model.prVarientList![model.selVarient!].disPrice!);
              if (price == 0) {
                price = double.parse(
                    model.prVarientList![model.selVarient!].price!);
              }

              double off = 0;
              if (model.prVarientList![model.selVarient!].disPrice! != '0') {
                off = (double.parse(
                            model.prVarientList![model.selVarient!].price!) -
                        double.parse(
                            model.prVarientList![model.selVarient!].disPrice!))
                    .toDouble();
                off = off *
                    100 /
                    double.parse(
                        model.prVarientList![model.selVarient!].price!);
              }

              return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Card(
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Hero(
                                    tag: 'ProList$index${model.id}',
                                    child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10)),
                                        child: Stack(
                                          children: [
                                            FadeInImage(
                                              image: CachedNetworkImageProvider(
                                                  model.image!),
                                              height: 125.0,
                                              width: 110.0,
                                              fit: extendImg
                                                  ? BoxFit.fill
                                                  : BoxFit.contain,
                                              imageErrorBuilder: (context,
                                                      error, stackTrace) =>
                                                  erroWidget(125),
                                              placeholder: placeHolder(125),
                                            ),
                                            Positioned.fill(
                                                child: model.availability == '0'
                                                    ? Container(
                                                        height: 55,
                                                        color: Colors.white70,
                                                        // width: double.maxFinite,
                                                        padding:
                                                            const EdgeInsets.all(2),
                                                        child: Center(
                                                          child: Text(
                                                            getTranslated(
                                                                context,
                                                                'OUT_OF_STOCK_LBL')!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .caption!
                                                                .copyWith(
                                                                  color: Colors
                                                                      .red,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      )
                                                    : Container()),
                                            (off != 0 ||
                                                    off != 0.0 ||
                                                    off != 0.00)
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                        color: colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Text(
                                                        off.toStringAsFixed(2) +
                                                            '%',
                                                        style: const TextStyle(
                                                            color: colors
                                                                .whiteTemp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 9),
                                                      ),
                                                    ),
                                                    margin: const EdgeInsets.all(5),
                                                  )
                                                : Container()
                                            // Container(
                                            //   decoration: BoxDecoration(
                                            //       color: colors.red,
                                            //       borderRadius:
                                            //           BorderRadius.circular(10)),
                                            //   child: Padding(
                                            //     padding: const EdgeInsets.all(5.0),
                                            //     child: Text(
                                            //       off.toStringAsFixed(2) + "%",
                                            //       style: TextStyle(
                                            //           color: colors.whiteTemp,
                                            //           fontWeight: FontWeight.bold,
                                            //           fontSize: 9),
                                            //     ),
                                            //   ),
                                            //   margin: EdgeInsets.all(5),
                                            // )
                                          ],
                                        ))),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      //mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          model.name!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        model.prVarientList![model.selVarient!]
                                                        .attr_name !=
                                                    '' &&
                                                model
                                                    .prVarientList![
                                                        model.selVarient!]
                                                    .attr_name!
                                                    .isNotEmpty
                                            ? ListView.builder(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: att.length >= 2
                                                    ? 2
                                                    : att.length,
                                                itemBuilder: (context, index) {
                                                  return Row(children: [
                                                    Flexible(
                                                      child: Text(
                                                        att[index].trim() + ':',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle2!
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .lightBlack),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .only(start: 5.0),
                                                      child: Text(
                                                        val[index],
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle2!
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .lightBlack,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                      ),
                                                    )
                                                  ]);
                                                })
                                            : Container(),
                                        (model.rating! == '0' ||
                                                model.rating! == '0.0')
                                            ? Container()
                                            : Row(
                                                children: [
                                                  RatingBarIndicator(
                                                    rating: double.parse(
                                                        model.rating!),
                                                    itemBuilder:
                                                        (context, index) =>
                                                            const Icon(
                                                      Icons.star_rate_rounded,
                                                      color: Colors.amber,
                                                      //color: colors.primary,
                                                    ),
                                                    unratedColor: Colors.grey
                                                        .withOpacity(0.5),
                                                    itemCount: 5,
                                                    itemSize: 18.0,
                                                    direction: Axis.horizontal,
                                                  ),
                                                  Text(
                                                    ' (' +
                                                        model.noOfRating! +
                                                        ')',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .overline,
                                                  )
                                                ],
                                              ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                                '${getPriceFormat(context,price)!} ',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                            Text(
                                              double.parse(model
                                                          .prVarientList![
                                                              model.selVarient!]
                                                          .disPrice!) !=
                                                      0
                                                  ? getPriceFormat(context,double.parse( model
                                                  .prVarientList![
                                              model.selVarient!]
                                                  .price!))!

                                                  : '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .overline!
                                                  .copyWith(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      letterSpacing: 0),
                                            ),
                                          ],
                                        ),
                                        _controller[index].text != '0'
                                            ? Row(
                                                children: [
                                                  //Spacer(),
                                                  model.availability == '0'
                                                      ? Container()
                                                      : cartBtnList
                                                          ? Row(
                                                              children: <
                                                                  Widget>[
                                                                Row(
                                                                  children: <
                                                                      Widget>[
                                                                    GestureDetector(
                                                                      child:
                                                                          Card(
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(50),
                                                                        ),
                                                                        child:
                                                                            const Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Icon(
                                                                            Icons.remove,
                                                                            size:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      onTap:
                                                                          () {
                                                                        if (_isProgress ==
                                                                                false &&
                                                                            (int.parse(_controller[index].text) >
                                                                                0)) {
                                                                          removeFromCart(
                                                                              index);
                                                                        }
                                                                      },
                                                                    ),
                                                                    SizedBox(
                                                                      width: 37,
                                                                      height:
                                                                          20,
                                                                      child:
                                                                          Stack(
                                                                        children: [
                                                                          Selector<
                                                                              CartProvider,
                                                                              Tuple2<List<String?>, List<String?>>>(
                                                                            builder: (context,
                                                                                data,
                                                                                child) {
                                                                              return TextField(
                                                                                textAlign: TextAlign.center,
                                                                                readOnly: true,
                                                                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.fontColor),
                                                                                controller: _controller[index],
                                                                                // _controller[index],
                                                                                decoration: const InputDecoration(
                                                                                  border: InputBorder.none,
                                                                                ),
                                                                              );
                                                                            },
                                                                            selector: (_, provider) =>
                                                                                Tuple2(provider.cartIdList, provider.qtyList),
                                                                          ),
                                                                          PopupMenuButton<
                                                                              String>(
                                                                            tooltip:
                                                                                '',
                                                                            icon:
                                                                                const Icon(
                                                                              Icons.arrow_drop_down,
                                                                              size: 1,
                                                                            ),
                                                                            onSelected:
                                                                                (String value) {
                                                                              if (_isProgress == false) {
                                                                                addToCart(index, value, 2);
                                                                              }
                                                                            },
                                                                            itemBuilder:
                                                                                (BuildContext context) {
                                                                              return model.itemsCounter!.map<PopupMenuItem<String>>((String value) {
                                                                                return PopupMenuItem(child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.fontColor)), value: value);
                                                                              }).toList();
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    // ),

                                                                    GestureDetector(
                                                                      child:
                                                                          Card(
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(50),
                                                                        ),
                                                                        child:
                                                                            const Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Icon(
                                                                            Icons.add,
                                                                            size:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      onTap:
                                                                          () {
                                                                        if (_isProgress ==
                                                                            false) {
                                                                          addToCart(
                                                                              index,
                                                                              (int.parse(model.prVarientList![model.selVarient!].cartCount!) + int.parse(model.qtyStepSize!)).toString(),
                                                                              2);
                                                                        }
                                                                      },
                                                                    )
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          : Container(),
                                                ],
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            // model.availability == "0"
                            //     ? Text(getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                            //         style: Theme.of(context)
                            //             .textTheme
                            //             .subtitle2!
                            //             .copyWith(
                            //                 color: Colors.red,
                            //                 fontWeight: FontWeight.bold))
                            //     : Container(),
                          ]),
                          onTap: () {
                            Product model = productList[index];

                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => ProductDetail(
                                        model: model,
                                        index: index,
                                        secPos: 0,
                                        list: true,
                                      )),
                            );
                          },
                        ),
                      ),
                      _controller[index].text == '0'
                          ? Positioned.directional(
                              textDirection: Directionality.of(context),
                              bottom: -15,
                              end: 45,
                              child: InkWell(
                                onTap: () {
                                  if (_isProgress == false) {
                                    addToCart(
                                        index,
                                        (int.parse(_controller[index].text) +
                                                int.parse(model.qtyStepSize!))
                                            .toString(),
                                        1);
                                  }
                                },
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      Positioned.directional(
                          textDirection: Directionality.of(context),
                          bottom: -15,
                          end: 0,
                          child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: model.isFavLoading!
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
                                        return InkWell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              !data.contains(model.id)
                                                  ? Icons.favorite_border
                                                  : Icons.favorite,
                                              size: 20,
                                            ),
                                          ),
                                          onTap: () {
                                            if (CUR_USERID != null) {
                                              !data.contains(model.id)
                                                  ? _setFav(-1, model)
                                                  : _removeFav(-1, model);
                                            } else {
                                              if (!data.contains(
                                                  model.id)) {
                                                model.isFavLoading =
                                                true;
                                                model.isFav = '1';
                                                context
                                                    .read<
                                                    FavoriteProvider>()
                                                    .addFavItem(
                                                    model);
                                                db.addAndRemoveFav(
                                                    model.id!, true);
                                                model.isFavLoading =
                                                false;
                                              } else {
                                                model.isFavLoading =
                                                true;
                                                model.isFav = '0';
                                                context
                                                    .read<
                                                    FavoriteProvider>()
                                                    .removeFavItem(model
                                                    .prVarientList![
                                                0]
                                                    .id!);
                                                db.addAndRemoveFav(
                                                    model.id!, false);
                                                model.isFavLoading =
                                                false;
                                              }
                                              setState(() {});
                                            }
                                          },
                                        );
                                      },
                                      selector: (_, provider) =>
                                          provider.favIdList,
                                    )))
                    ],
                  ));
            } else {
              return Container();
            }
          });
    } else {
      return Container();
    }
  }

  _setFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          index == -1 ? model.isFav = '1' : productList[index].isFav = '1';

          context.read<FavoriteProvider>().addFavItem(model);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted) {
          setState(() {
            index == -1
                ? model.isFavLoading = false
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

  _removeFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(removeFavApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          index == -1 ? model.isFav = '0' : productList[index].isFav = '0';
          context
              .read<FavoriteProvider>()
              .removeFavItem(model.prVarientList![0].id!);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted) {
          setState(() {
            index == -1
                ? model.isFavLoading = false
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

  /*_setFav(Product model) async {
     _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (mounted)
        setState(() {
          model.isFavLoading = true;
        });

      var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};

      apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          model.isFav = "1";
          context.read<FavoriteProvider>().addFavItem(model);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            model.isFavLoading = false;
          });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _removeFav(Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (mounted)
        setState(() {
          model.isFavLoading = true;
        });

      var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};

      apiBaseHelper.postAPICall(removeFavApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          model.isFav = "0";

          /*  favList.removeWhere((item) =>
          item.productList![0].prVarientList![0].id ==
              widget.model!.prVarientList![0].id);*/
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            model.isFavLoading = false;
          });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }*/

  removeFromCart(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }

        int qty;

        qty =
            /*      (int.parse(productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount!)*/
            (int.parse(_controller[index].text) -
                int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
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
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();

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
        setState(() {
          _isProgress = true;
        });

        int qty;

        qty = (int.parse(_controller[index].text) -
            int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;

          db.removeCart(
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!,
              productList[index].id!,
              context);
        } else {
          db.updateCart(
              productList[index].id!,
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!,
              qty.toString());
        }
        setState(() {
          _isProgress = false;
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

  void getProduct(String top) {
    //_currentRangeValues.start.round().toString(),
    // _currentRangeValues.end.round().toString(),
    Map parameter = {
      SORT: sortBy,
      ORDER: orderBy,
      LIMIT: perPage.toString(),
      OFFSET: offset.toString(),
      TOP_RETAED: top,
    };
    if (selId != '') {
      parameter[ATTRIBUTE_VALUE_ID] = selId;
    }
    if (widget.tag!) parameter[TAG] = widget.name!;
    if (widget.fromSeller!) {
      parameter['seller_id'] = widget.id!;
    } else {
      parameter[CATID] = widget.id ?? '';
    }
    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;

    if (widget.dis != null) parameter[DISCOUNT] = widget.dis.toString();

    if (_currentRangeValues != null &&
        _currentRangeValues!.start.round().toString() != '0') {
      parameter[MINPRICE] = _currentRangeValues!.start.round().toString();
    }

    if (_currentRangeValues != null &&
        _currentRangeValues!.end.round().toString() != '0') {
      parameter[MAXPRICE] = _currentRangeValues!.end.round().toString();
    }

    apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
      bool error = getdata['error'];
      String? msg = getdata['message'];


      if (!error) {
        total = int.parse(getdata['total']);

        if (_isFirstLoad) {
          filterList = getdata['filters'];

          minPrice = getdata[MINPRICE].toString();
          maxPrice = getdata[MAXPRICE].toString();
          _currentRangeValues =
              RangeValues(double.parse(minPrice), double.parse(maxPrice));
          _isFirstLoad = false;
        }

        if ((offset) < total) {
          tempList.clear();

          var data = getdata['data'];
          tempList =
              (data as List).map((data) => Product.fromJson(data)).toList();


          if (getdata.containsKey(TAG)) {
            List<String> tempList = List<String>.from(getdata[TAG]);
            if (tempList.isNotEmpty) tagList = tempList;
          }

          getAvailVarient();

          offset = offset + perPage;
        } else {
          if (msg != 'Products Not Found !') setSnackbar(msg!, context);
          isLoadingmore = false;
        }
      } else {
        isLoadingmore = false;
        if (msg != 'Products Not Found !') setSnackbar(msg!, context);
      }

      setState(() {
        _isLoading = false;
      });
      // context.read<ProductListProvider>().setProductLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      setState(() {
        _isLoading = false;
      });
      //context.read<ProductListProvider>().setProductLoading(false);
    });
  }

  void getAvailVarient() {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == '2') {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == '1') {
            tempList[j].selVarient = i;

            break;
          }
        }
      }
    }
    productList.addAll(tempList);
  }

/*  getAppbar() {
    String cartCount =
        Provider.of<UserProvider>(context, listen: false).curCartCount;
    return AppBar(
      titleSpacing: 0,
      iconTheme: IconThemeData(color: colors.primary),
      title: Text(
        widget.name!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
        ),
      ),
      elevation: 5,
      backgroundColor: Theme.of(context).colorScheme.white,
      leading: Builder(builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(10),

          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 4.0),
              child: Icon( Icons.arrow_back_ios_rounded, color: colors.primary),
            ),
          ),
        );
      }),
      actions: <Widget>[
        */ /*  Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => Search(),
                    ));
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.search,
                  color: colors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: shadow(),
            child: Card(
                elevation: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          listType ? Icons.grid_view : Icons.list,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      onTap: () {
                        productList.length != 0
                            ? setState(() {
                                listType = !listType;
                              })
                            : null;
                      }),
                ))),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                CUR_USERID == null
                    ? Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => Login(),
                        ))
                    : Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => Cart(),
                        ));
              },
              child: new Stack(children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SvgPicture.asset(
                      'assets/images/noti_cart.png',
                    ),
                  ),
                ),
                (cartCount.isNotEmpty && cartCount != "0")
                    ? new Positioned(
                        top: 0.0,
                        right: 5.0,
                        bottom: 10,
                        child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withOpacity(0.5)),
                            child: new Center(
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: new Text(
                                  cartCount,
                                  style: TextStyle(
                                      fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      )
                    : Container()
              ]),
            ),
          ),
        ),
        Container(
            width: 40,
            margin: EdgeInsetsDirectional.only(top: 10, bottom: 10, end: 5),
            decoration: shadow(),
            child: Card(
                elevation: 0,
                child: Material(
                    color: Colors.transparent,
                    child: PopupMenuButton(
                      padding: EdgeInsets.zero,
                      onSelected: (dynamic value) {
                        switch (value) {
                          case 0:
                            return filterDialog();

                          case 1:
                            return sortDialog();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          value: 0,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsetsDirectional.only(
                                start: 0.0, end: 0.0),
                            leading: Icon(
                              Icons.tune,
                              color: Theme.of(context).colorScheme.fontColor,
                              size: 20,
                            ),
                            title: Text('Filter'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 1,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsetsDirectional.only(
                                start: 0.0, end: 0.0),
                            leading: Icon(Icons.sort,
                                color: Theme.of(context).colorScheme.fontColor, size: 20),
                            title: Text('Sort'),
                          ),
                        ),
                      ],
                    )))),*/ /*
      ],
    );
  }*/

  Widget productItem(int index, bool pad) {
    if (index < productList.length) {
      Product model = productList[index];
      return FutureBuilder(
          future: db.checkCartItemExists(
              model.id!, model.prVarientList![model.selVarient!].id!),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              totalProduct = model.total;

              if (_controller.length < index + 1) {
                _controller.add(TextEditingController());
              }

              if (CUR_USERID == null) {
                model.prVarientList![model.selVarient!].cartCount =
                    snapshot.data;
                _controller[index].text = snapshot.data;
              } else {
                _controller[index].text =
                    model.prVarientList![model.selVarient!].cartCount!;
              }
              double price = double.parse(
                  model.prVarientList![model.selVarient!].disPrice!);
              if (price == 0) {
                price = double.parse(
                    model.prVarientList![model.selVarient!].price!);
              }

              double off = 0;
              if (model.prVarientList![model.selVarient!].disPrice! != '0') {
                off = (double.parse(
                            model.prVarientList![model.selVarient!].price!) -
                        double.parse(
                            model.prVarientList![model.selVarient!].disPrice!))
                    .toDouble();
                off = off *
                    100 /
                    double.parse(
                        model.prVarientList![model.selVarient!].price!);
              }

              List att = [], val = [];
              if (model.prVarientList![model.selVarient!].attr_name != '') {
                att = model.prVarientList![model.selVarient!].attr_name!
                    .split(',');
                val = model.prVarientList![model.selVarient!].varient_value!
                    .split(',');
              }
              double width = deviceWidth! * 0.5;

              return InkWell(
                child: Card(
                  elevation: 0.2,
                  margin: EdgeInsetsDirectional.only(
                      bottom: 10, end: 10, start: pad ? 10 : 0),
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
                                tag: "ProGrid$index${model.id}",
                                child: FadeInImage(
                                  fadeInDuration: const Duration(milliseconds: 150),
                                  image:
                                      CachedNetworkImageProvider(model.image!),
                                  height: double.maxFinite,
                                  width: double.maxFinite,
                                  fit: extendImg
                                      ? BoxFit.fill
                                      : BoxFit.fitHeight,
                                  placeholder: placeHolder(width),
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          erroWidget(width),
                                ),
                              ),
                            ),
                            Positioned.fill(
                                child: model.availability == '0'
                                    ? Container(
                                        height: 55,
                                        color: Colors.white70,
                                        // width: double.maxFinite,
                                        padding: const EdgeInsets.all(2),
                                        child: Center(
                                          child: Text(
                                            getTranslated(
                                                context, 'OUT_OF_STOCK_LBL')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption!
                                                .copyWith(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : Container()),
                            (off != 0 || off != 0.0 || off != 0.00)
                                ? Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          off.toStringAsFixed(2) + '%',
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
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              end: 0,
                              // bottom: -18,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  model.availability == '0' && !cartBtnList
                                      ? Container()
                                      : _controller[index].text == '0'
                                          ? InkWell(
                                              onTap: () {
                                                if (_isProgress == false) {
                                                  addToCart(
                                                      index,
                                                      (int.parse(_controller[
                                                                      index]
                                                                  .text) +
                                                              int.parse(model
                                                                  .qtyStepSize!))
                                                          .toString(),
                                                      1);
                                                }
                                              },
                                              child: Card(
                                                elevation: 1,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: const Padding(
                                                  padding:
                                                      EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                          .only(
                                                      start: 3.0,
                                                      bottom: 5,
                                                      top: 3),
                                              child: Row(
                                                children: <Widget>[
                                                  GestureDetector(
                                                    child: Card(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(
                                                          Icons.remove,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      if (_isProgress ==
                                                              false &&
                                                          (int.parse(
                                                                  _controller[
                                                                          index]
                                                                      .text) >
                                                              0)) {
                                                        removeFromCart(index);
                                                      }
                                                    },
                                                  ),
                                                  Container(
                                                    width: 26,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      color: colors.white70,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Selector<
                                                            CartProvider,
                                                            Tuple2<
                                                                List<String?>,
                                                                List<String?>>>(
                                                          builder: (context,
                                                              data, child) {
                                                            return TextField(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              readOnly: true,
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .fontColor),
                                                              controller:
                                                                  _controller[
                                                                      index],
                                                              decoration:
                                                                  const InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                              ),
                                                            );
                                                          },
                                                          selector: (_, provider) =>
                                                              Tuple2(
                                                                  provider
                                                                      .cartIdList,
                                                                  provider
                                                                      .qtyList),
                                                        ),
                                                        PopupMenuButton<String>(
                                                          tooltip: '',
                                                          icon: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 0,
                                                          ),
                                                          onSelected:
                                                              (String value) {
                                                            if (_isProgress ==
                                                                false) {
                                                              addToCart(index,
                                                                  value, 2);
                                                            }
                                                          },
                                                          itemBuilder:
                                                              (BuildContext
                                                                  context) {
                                                            return model
                                                                .itemsCounter!
                                                                .map<
                                                                    PopupMenuItem<
                                                                        String>>((String
                                                                    value) {
                                                              return PopupMenuItem(
                                                                  child:
                                                                      Text(
                                                                    value,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .fontColor,
                                                                    ),
                                                                  ),
                                                                  value: value);
                                                            }).toList();
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ), // ),

                                                  GestureDetector(
                                                    child: Card(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      if (_isProgress == false) {
                                                        addToCart(
                                                            index,
                                                            (int.parse(_controller[
                                                                            index]
                                                                        .text) +
                                                                    int.parse(model
                                                                        .qtyStepSize!))
                                                                .toString(),
                                                            2);
                                                      }
                                                    },
                                                  )
                                                ],
                                              ),
                                            ),
                                  Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: model.isFavLoading!
                                          ? const Padding(
                                              padding:
                                                  EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                  height: 15,
                                                  width: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 0.7,
                                                  )),
                                            )
                                          : Selector<FavoriteProvider,
                                              List<String?>>(
                                              builder: (context, data, child) {
                                                return InkWell(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Icon(
                                                      !data.contains(model.id)
                                                          ? Icons
                                                              .favorite_border
                                                          : Icons.favorite,
                                                      size: 15,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    if (CUR_USERID != null) {
                                                      !data.contains(model.id)
                                                          ? _setFav(-1, model)
                                                          : _removeFav(
                                                              -1, model);
                                                    } else {
                                                      if (!data.contains(
                                                          model.id)) {
                                                        model.isFavLoading =
                                                        true;
                                                        model.isFav = '1';
                                                        context
                                                            .read<
                                                            FavoriteProvider>()
                                                            .addFavItem(
                                                            model);
                                                        db.addAndRemoveFav(
                                                            model.id!, true);
                                                        model.isFavLoading =
                                                        false;
                                                      } else {
                                                        model.isFavLoading =
                                                        true;
                                                        model.isFav = '0';
                                                        context
                                                            .read<
                                                            FavoriteProvider>()
                                                            .removeFavItem(model
                                                            .prVarientList![
                                                        0]
                                                            .id!);
                                                        db.addAndRemoveFav(
                                                            model.id!, false);
                                                        model.isFavLoading =
                                                        false;
                                                      }
                                                      setState(() {});
                                                    }
                                                  },
                                                );
                                              },
                                              selector: (_, provider) =>
                                                  provider.favIdList,
                                            )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      (model.rating! == '0' || model.rating! == '0.0')
                          ? Container()
                          : Row(
                              children: [
                                RatingBarIndicator(
                                  rating: double.parse(model.rating!),
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
                                  ' (' + model.noOfRating! + ')',
                                  style: Theme.of(context).textTheme.overline,
                                )
                              ],
                            ),
                      Row(
                        children: [
                          Text(
                              ' ${getPriceFormat(context,price)!} ',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold)),
                          double.parse(model.prVarientList![model.selVarient!]
                                      .disPrice!) !=
                                  0
                              ? Flexible(
                                  child: Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          double.parse(model
                                                      .prVarientList![
                                                          model.selVarient!]
                                                      .disPrice!) !=
                                                  0
                                              ? getPriceFormat(context,double.parse( model
                                              .prVarientList![
                                          model.selVarient!]
                                              .price!))!
                                              : '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline!
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  letterSpacing: 0),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container()
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: model.prVarientList![model.selVarient!]
                                              .attr_name !=
                                          '' &&
                                      model.prVarientList![model.selVarient!]
                                          .attr_name!.isNotEmpty
                                  ? ListView.builder(
                                      padding:
                                          const EdgeInsets.only(bottom: 5.0),
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount:
                                          att.length >= 2 ? 2 : att.length,
                                      itemBuilder: (context, index) {
                                        return Row(children: [
                                          Flexible(
                                            child: Text(
                                              att[index].trim() + ':',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(
                                                      start: 5.0),
                                              child: Text(
                                                val[index],
                                                maxLines: 1,
                                                overflow: TextOverflow.visible,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack,
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                          )
                                        ]);
                                      })
                                  : Container(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 5.0, bottom: 5),
                        child: Text(
                          model.name!,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  //),
                ),
                onTap: () {
                  Product model = productList[index];
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ProductDetail(
                              model: model,
                              index: index,
                              secPos: 0,
                              list: true,
                            )),
                  );
                },
              );
            } else {
              return Container();
            }
          });
    } else {
      return Container();
    }
  }

  void sortDialog() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.white,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                        padding:
                            const EdgeInsetsDirectional.only(top: 19.0, bottom: 16.0),
                        child: Text(
                          getTranslated(context, 'SORT_BY')!,
                          style: Theme.of(context)
                              .textTheme
                              .headline6!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                        )),
                  ),
                  InkWell(
                    onTap: () {
                      sortBy = '';
                      orderBy = 'DESC';
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          total = 0;
                          offset = 0;
                          productList.clear();
                        });
                      }
                      getProduct('1');
                      Navigator.pop(context, 'option 1');
                    },
                    child: Container(
                      width: deviceWidth,
                      color: sortBy == ''
                          ? colors.primary
                          : Theme.of(context).colorScheme.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Text(getTranslated(context, 'TOP_RATED')!,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color: sortBy == ''
                                      ? Theme.of(context).colorScheme.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .fontColor)),
                    ),
                  ),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'p.date_added' && orderBy == 'DESC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(getTranslated(context, 'F_NEWEST')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: sortBy == 'p.date_added' &&
                                              orderBy == 'DESC'
                                          ? Theme.of(context).colorScheme.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .fontColor))),
                      onTap: () {
                        sortBy = 'p.date_added';
                        orderBy = 'DESC';
                        if (mounted) {
                          setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }
                        getProduct('0');
                        Navigator.pop(context, 'option 1');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'p.date_added' && orderBy == 'ASC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_OLDEST')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                    color: sortBy == 'p.date_added' &&
                                            orderBy == 'ASC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'p.date_added';
                        orderBy = 'ASC';
                        if (mounted) {
                          setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }
                        getProduct('0');
                        Navigator.pop(context, 'option 2');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'pv.price' && orderBy == 'ASC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_LOW')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                    color: sortBy == 'pv.price' &&
                                            orderBy == 'ASC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'pv.price';
                        orderBy = 'ASC';
                        if (mounted) {
                          setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }
                        getProduct('0');
                        Navigator.pop(context, 'option 3');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'pv.price' && orderBy == 'DESC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_HIGH')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                    color: sortBy == 'pv.price' &&
                                            orderBy == 'DESC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'pv.price';
                        orderBy = 'DESC';
                        if (mounted) {
                          setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }
                        getProduct('0');
                        Navigator.pop(context, 'option 4');
                      }),
                ]),
          );
        });
      },
    );
  }

/*  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        if (mounted)
          setState(() {
            isLoadingmore = true;

            if (offset < total) getProduct("0");
          });
      }
    }
  }*/

  Future<void> addToCart(int index, String qty, int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }

        if (int.parse(qty) < productList[index].minOrderQuntity!) {
          qty = productList[index].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          QTY: qty
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            var data = getdata['data'];

            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();

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
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        });
      } else {
        setState(() {
          _isProgress = true;
        });

        if (from == 1) {
          db.insertCart(
              productList[index].id!,
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!,
              qty,
              context);
        } else {
          if (int.parse(qty) > productList[index].itemsCounter!.length) {
            // qty = productList[index].minOrderQuntity.toString();

            setSnackbar('Max Quantity is-${int.parse(qty) - 1}', context);
          } else {
            db.updateCart(
                productList[index].id!,
                productList[index]
                    .prVarientList![productList[index].selVarient!]
                    .id!,
                qty);
          }
        }
        setState(() {
          _isProgress = false;
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

/*  Future<Null>  _refresh() {

 */ /*   if (mounted)
      setState(() {
        _isLoading = true;
        isLoadingmore = true;
        offset = 0;
        total = 0;
        productList.clear();
      });
    getProduct("0");*/ /*

  }*/

  _showForm(BuildContext context) {
    return Column(
      children: [
        productList.isEmpty
            ? Container()
            : Container(
                color: Theme.of(context).colorScheme.white,
                child: Column(
                  children: [
                    if (widget.fromSeller!) Container() else _tags(),
                    filterOptions(),
                  ],
                ),
              ),
        Expanded(
            child: productList.isEmpty
                ? getNoItem(context)
                : Selector<ProductDetailProvider, bool>(
                    builder: (context, data, child) {
                      return data
                          ? ListView.builder(
                              controller: controller,
                              itemCount: (offset < total)
                                  ? productList.length + 1
                                  : productList.length,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return (index == productList.length &&
                                        isLoadingmore)
                                    ? singleItemSimmer(context)
                                    : listItem(index);
                              },
                            )
                          : GridView.count(
                              padding: const EdgeInsetsDirectional.only(top: 5),
                              crossAxisCount: 2,
                              controller: controller,
                              childAspectRatio: 0.78,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: List.generate(
                                (offset < total)
                                    ? productList.length + 1
                                    : productList.length,
                                (index) {
                                  return (index == productList.length &&
                                          isLoadingmore)
                                      ? simmerSingleProduct(context)
                                      : productItem(
                                          index, index % 2 == 0 ? true : false);
                                },
                              ));
                    },
                    selector: (_, ProductDetailsProvider) =>
                        ProductDetailsProvider.listType,
                  )),
      ],
    );
  }

  Widget _tags() {
    if (tagList != null && tagList!.isNotEmpty) {
      List<Widget> chips = [];
      for (int i = 0; i < tagList!.length; i++) {
        tagChip = ChoiceChip(
          selected: false,
          label: Text(tagList![i], style: const TextStyle(color: colors.whiteTemp)),
          backgroundColor: colors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          onSelected: (bool selected) {
             if (mounted) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ProductList(
                      name: tagList![i],
                      tag: true,
                      fromSeller: false,
                    ),
                  ));
            }
          },
        );

        chips.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5), child: tagChip));
      }

      return Container(
        height: 50,
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: chips),
      );
    } else {
      return Container();
    }
  }

  filterOptions() {
    return Container(
      color: Theme.of(context).colorScheme.gray,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: filterDialog,
            icon: const Icon(
              Icons.filter_list,
              color: colors.primary,
            ),
            label: Text(
              getTranslated(context, 'FILTER')!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: sortDialog,
            icon: const Icon(
              Icons.swap_vert,
              color: colors.primary,
            ),
            label: Text(
              getTranslated(context, 'SORT_BY')!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
              ),
            ),
          ),
          /* InkWell(
            child: Icon(
              listType ? Icons.grid_view : Icons.list,
              color: colors.primary,
            ),
            onTap: () {
              productList.length != 0
                  ? setState(() {
                      listType = !listType;
                    })
                  : null;
            },
          ),*/
          InkWell(
            child: AnimatedIcon(
              icon: AnimatedIcons.list_view,
              color: colors.primary,
              progress: listViewIconController,
            ),
            onTap: () {
              if (productList.isNotEmpty) {
                context.read<ProductDetailProvider>().setListType(
                    !context.read<ProductDetailProvider>().listType);
              }

              context.read<ProductDetailProvider>().listType
                  ? listViewIconController.reverse()
                  : listViewIconController.forward();
            },
          ),
        ],
      ),
    );
  }

  void filterDialog() {
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsetsDirectional.only(top: 30.0),
                child: AppBar(
                  title: Text(
                    getTranslated(context, 'FILTER')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 5,
                  backgroundColor: Theme.of(context).colorScheme.white,
                  leading: Builder(builder: (BuildContext context) {
                    return Container(
                      margin: const EdgeInsets.all(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(end: 4.0),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: colors.primary),
                        ),
                      ),
                    );
                  }),
                )),
            Expanded(
                child: Container(
              color: Theme.of(context).colorScheme.lightWhite,
              padding:
                  const EdgeInsetsDirectional.only(start: 7.0, end: 7.0, top: 7.0),
              child: filterList != null
                  ? ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsetsDirectional.only(top: 10.0),
                      itemCount: filterList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              SizedBox(
                                  width: deviceWidth,
                                  child: Card(
                                      elevation: 0,
                                      child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Price Range',
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                    fontWeight:
                                                        FontWeight.normal),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          )))),
                              RangeSlider(
                                values: _currentRangeValues!,
                                min: double.parse(minPrice),
                                max: double.parse(maxPrice),
                                divisions: 10,
                                labels: RangeLabels(
                                  _currentRangeValues!.start.round().toString(),
                                  _currentRangeValues!.end.round().toString(),
                                ),
                                onChanged: (RangeValues values) {
                                  setState(() {
                                    _currentRangeValues = values;
                                  });
                                },
                              ),
                            ],
                          );
                        } else {
                          index = index - 1;
                          attsubList =
                              filterList[index]['attribute_values'].split(',');

                          attListId = filterList[index]['attribute_values_id']
                              .split(',');

                          List<Widget?> chips = [];
                          List<String> att =
                              filterList[index]['attribute_values']!.split(',');

                          List<String> attSType =
                              filterList[index]['swatche_type'].split(',');

                          List<String> attSValue =
                              filterList[index]['swatche_value'].split(',');


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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              erroWidget(80)));
                            } else {
                              itemLabel = Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(att[i],
                                    style: TextStyle(
                                        color:
                                            selectedId.contains(attListId![i])
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .fontColor)),
                              );
                            }

                            choiceChip = ChoiceChip(
                              selected: selectedId.contains(attListId![i]),
                              label: itemLabel,
                              labelPadding: const EdgeInsets.all(0),
                              selectedColor: colors.primary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    attSType[i] == '1' ? 100 : 10),
                                side: BorderSide(
                                    color: selectedId.contains(attListId![i])
                                        ? colors.primary
                                        : colors.black12,
                                    width: 1.5),
                              ),
                              onSelected: (bool selected) {
                                attListId = filterList[index]
                                        ['attribute_values_id']
                                    .split(',');

                                if (mounted) {
                                  setState(() {
                                    if (selected == true) {
                                      selectedId.add(attListId![i]);
                                    } else {
                                      selectedId.remove(attListId![i]);
                                    }
                                  });
                                }
                              },
                            );

                            chips.add(choiceChip);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: deviceWidth,
                                child: Card(
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      filterList[index]['name'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ),
                              chips.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Wrap(
                                        children:
                                            chips.map<Widget>((Widget? chip) {
                                          return Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: chip,
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : Container()

                              /*    (filter == filterList[index]["name"])
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      NeverScrollableScrollPhysics(),
                                  itemCount: attListId!.length,
                                  itemBuilder: (context, i) {

                                    */ /*       return CheckboxListTile(
                                  dense: true,
                                  title: Text(attsubList![i],
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Theme.of(context).colorScheme.lightBlack,
                                              fontWeight:
                                                  FontWeight.normal)),
                                  value: selectedId
                                      .contains(attListId![i]),
                                  activeColor: colors.primary,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (bool? val) {
                                    if (mounted)
                                      setState(() {
                                        if (val == true) {
                                          selectedId.add(attListId![i]);
                                        } else {
                                          selectedId
                                              .remove(attListId![i]);
                                        }
                                      });
                                  },
                                );*/ /*
                                  })
                              : Container()*/
                            ],
                          );
                        }
                      })
                  : Container(),
            )),
            Container(
              color: Theme.of(context).colorScheme.white,
              child: Row(children: <Widget>[
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 20),
                  width: deviceWidth! * 0.4,
                  child: OutlinedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          selectedId.clear();
                        });
                      }
                    },
                    child: Text(getTranslated(context, 'DISCARD')!),
                  ),
                ),
                const Spacer(),
                SimBtn(
                    size: 0.4,
                    title: getTranslated(context, 'APPLY'),
                    onBtnSelected: () {
                      if (selectedId != null) {
                        selId = selectedId.join(',');
                      }

                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          total = 0;
                          offset = 0;
                          productList.clear();
                        });
                      }
                      getProduct('0');
                      Navigator.pop(context, 'Product Filter');
                    }),
              ]),
            )
          ]);
        });
      },
    );
  }
}
