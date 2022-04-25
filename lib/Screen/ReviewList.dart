import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Screen/write_review.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Provider/order_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'Product_Detail.dart';
import '../Model/User.dart';
import 'Product_Preview.dart';
import 'Review_Gallary.dart';
import 'Review_Preview.dart';

class ReviewList extends StatefulWidget {
  final String? id;
  final Product? model;

  const ReviewList(this.id, this.model, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateRate();
  }
}

class StateRate extends State<ReviewList> {
  bool _isNetworkAvail = true;
  bool _isLoading = true;

  // bool _isProgress = false, _isLoading = true;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  List<User> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isPhotoVisible = true;
  var star1 = '0',
      star2 = '0',
      star3 = '0',
      star4 = '0',
      star5 = '0',
      averageRating = '0';
  String? userComment = '', userRating = '0.0';

  @override
  void initState() {

    for (var element in reviewList) {

      if (element.userId == CUR_USERID) {
        userComment = element.comment;
        userRating = element.rating;
      }
    }
    getReview('0');
    controller.addListener(_scrollListener);
    Future.delayed(Duration.zero, () {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrderDetails(CUR_USERID, 'delivered');
    });

    super.initState();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;
            if (offset < total) {
              getReview(offset.toString());
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar:
            getAppBar(getTranslated(context, 'CUSTOMER_REVIEW_LBL')!, context),
        body: _review(),
        floatingActionButton: widget.model!.isPurchased == 'true'
            ? FloatingActionButton.extended(
                icon: const Icon(
                  Icons.create,
                  size: 20,
                ),
                label: userRating != '0' || userComment != ''
                    ? Text(
                        getTranslated(context, 'UPDATE_REVIEW_LBL')!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.white,
                            fontSize: 14),
                      )
                    : Text(
                        getTranslated(context, 'WRITE_REVIEW_LBL')!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.white,
                            fontSize: 14),
                      ),
                onPressed: () {
                  openBottomSheet(context, widget.id, userComment,
                      double.parse(userRating!));
                },
              )
            : Container());
  }

  Future<void> openBottomSheet(BuildContext context, var productID,
      var userReview, double userRating) async {
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Write_Review(
              _scaffoldKey.currentContext!, widget.id!, userReview, userRating);
        }).then((value) {
      getReview('0');
    });
  }

  Widget _review() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    //mainAxisSize: MainAxisSize.min,
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        averageRating,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
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
            ),
          ),
          revImgList.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 0.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            getTranslated(context, 'REVIEW_BY_CUST')!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        _reviewImg(),
                      ],
                    ),
                  ),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "${reviewList.length} ${getTranslated(context, "REVIEW_LBL")}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
                revImgList.isNotEmpty
                    ? Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                isPhotoVisible = !isPhotoVisible;
                              });
                            },
                            child: Container(
                              height: 20.0,
                              width: 20.0,
                              decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: isPhotoVisible
                                      ? colors.primary
                                      : Theme.of(context).colorScheme.white,
                                  borderRadius: BorderRadius.circular(3.0),
                                  border: Border.all(
                                    color: colors.primary,
                                  )),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: isPhotoVisible
                                    ? Icon(
                                        Icons.check,
                                        size: 15.0,
                                        color:
                                            Theme.of(context).colorScheme.white,
                                      )
                                    : Container(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "${getTranslated(context, "WITH_PHOTO")}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
          ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              controller: controller,
              itemCount:
                  (offset < total) ? reviewList.length + 1 : reviewList.length,
              // physics: BouncingScrollPhysics(),
              // separatorBuilder: (BuildContext context, int index) => Divider(),
              itemBuilder: (context, index) {
                if (index == reviewList.length && isLoadingmore) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: colors.primary,
                  ));
                } else {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reviewList[index].username!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RatingBarIndicator(
                                      rating: double.parse(
                                          reviewList[index].rating!),
                                      itemBuilder: (context, index) =>
                                          const Icon(
                                        Icons.star,
                                            color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 12.0,
                                      direction: Axis.horizontal,
                                    ),
                                    const Spacer(),
                                    Text(
                                      reviewList[index].date!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack2,
                                          fontSize: 11),
                                    )
                                  ],
                                ),
                                reviewList[index].comment != '' &&
                                        reviewList[index].comment!.isNotEmpty
                                    ? Text(
                                        reviewList[index].comment ?? '',
                                        textAlign: TextAlign.left,
                                      )
                                    : Container(),
                                isPhotoVisible
                                    ? reviewImage(index)
                                    : Container()
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                          child:
                              //  Image.network(reviewList[index].userProfile)

                              FadeInImage(
                            fadeInDuration: const Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(
                                reviewList[index].userProfile!),
                            fit: BoxFit.fill,
                            height: 36,
                            width: 36,
                            placeholder: placeHolder(36),
                            imageErrorBuilder: (context, error, stackTrace) =>
                                errorWidget(36),
                          ),
                        ),

                        /*     CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.primary,
                            // child: ClipRRect(
                            //   child: FadeInImage(
                            //     fadeInDuration: const Duration(milliseconds: 150),
                            //     image: CachedNetworkImageProvider(reviewList[index].userProfile!),
                            //     fit: BoxFit.fill,
                            //     placeholder: placeHolder(100),
                            //     imageErrorBuilder: (context, error, stackTrace) =>
                            //         erroWidget(100),
                            //   ),
                            // ),
                          backgroundImage: CachedNetworkImageProvider(reviewList[index].userProfile!),
                        ),*/
                      ),
                    ],
                  );
                }
              }),
        ],
      ),
    );
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
                  child: InkWell(
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

  reviewImage(int i) {
    return SizedBox(
      height: reviewList[i].imgList!.isNotEmpty ? 100 : 0,
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
                        secPos: 0,
                        index: 0,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                        screenSize: MediaQuery.of(context).size,
                      ),
                    ));
              },
              child: Hero(
                tag: /*$index*/ '$index${reviewList[i].id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: FadeInImage(
                    image: CachedNetworkImageProvider(
                        reviewList[i].imgList![index]),
                    height: 100.0,
                    width: 100.0,
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

  Future<void> getReview(var offset) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_ID: widget.id,
          LIMIT: perPage.toString(),
          OFFSET: offset,
        };

        Response response =
            await post(getRatingApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];

        if (!error) {
          star1 = getdata['star_1'];
          star2 = getdata['star_2'];
          star3 = getdata['star_3'];
          star4 = getdata['star_4'];
          star5 = getdata['star_5'];
          averageRating = getdata['product_rating'];

          total = int.parse(getdata['total']);
          offset = int.parse(offset);

          if (offset < total) {
            var data = getdata['data'];
            reviewList =
                (data as List).map((data) => User.forReview(data)).toList();

            offset = offset + perPage;
          }
        } else {
          if (msg != 'No ratings found !') setSnackbar(msg!);

        }
        if (mounted) {
          setState(() {
            isLoadingmore = false;
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
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
                  color: colors.primary,
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

  getTotalStarRating(var totalStar) {
    return SizedBox(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ));
  }
}
