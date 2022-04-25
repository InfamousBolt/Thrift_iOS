import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Screen/ProductList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SellerProfile extends StatefulWidget {
  final String? sellerID,
      sellerName,
      sellerImage,
      sellerRating,
      storeDesc,
      sellerStoreName;

  const SellerProfile(
      {Key? key,
      this.sellerID,
      this.sellerName,
      this.sellerImage,
      this.sellerRating,
      this.storeDesc,
      this.sellerStoreName})
      : super(key: key);

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  ApiBaseHelper apiBaseHelper = ApiBaseHelper();
  late TabController _tabController;

  bool isDescriptionVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: getAppBar(getTranslated(context, 'SELLER_DETAILS')!, context),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: getTranslated(context, 'DETAILS')!),
                  Tab(text: getTranslated(context, 'PRODUCTS')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    detailsScreen(),
                    ProductList(
                      fromSeller: true,
                      name: '',
                      id: widget.sellerID,
                      tag: false,
                    )
                  ],
                ),
              ),
            ],
          ),
          // bottomNavigationBar:
        ),
      ),
    );
  }

  // Future fetchSellerDetails() async {
  //   var parameter = {};
  //   final sellerData = await apiBaseHelper.postAPICall(getSellerApi, parameter);
  //   List<Seller> sellerDetails = [];
  //   bool error = sellerData["error"];
  //   String? msg = sellerData["message"];
  //   if (!error) {
  //     var data = sellerData["data"];
  //     sellerDetails =
  //         (data as List).map((data) => Seller.fromJson(data)).toList();
  //   } else {
  //     setSnackbar(msg!, context);
  //   }
  //
  //   return sellerDetails;
  // }

  Widget detailsScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: CircleAvatar(
              radius: 80,
              backgroundColor: colors.primary,
              backgroundImage: NetworkImage(widget.sellerImage!),
            ),
          ),
          getHeading(widget.sellerStoreName!),
          const SizedBox(
            height: 5,
          ),
          Text(
            widget.sellerName!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.lightBlack2, fontSize: 16),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          color: colors.primary),
                      child: const Icon(
                        Icons.star,
                        color: colors.whiteTemp,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      widget.sellerRating!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: colors.primary),
                        child: const Icon(
                          Icons.description,
                          color: colors.whiteTemp,
                          size: 30,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          isDescriptionVisible = !isDescriptionVisible;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      getTranslated(context, 'DESCRIPTION')!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              color: colors.primary),
                          child: const Icon(
                            Icons.list_alt,
                            color: colors.whiteTemp,
                            size: 30,
                          ),
                        ),
                        onTap: () => _tabController
                            .animateTo((_tabController.index + 1) % 2)),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      getTranslated(context, 'PRODUCTS')!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Visibility(
              visible: isDescriptionVisible,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 8,
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: colors.primary)),
                child: SingleChildScrollView(
                    child: Text(
                  (widget.storeDesc != '')
                      ? '${widget.storeDesc}'
                      : getTranslated(context, 'NO_DESC')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )),
              ))
        ],
      ),
    );
    // return FutureBuilder(
    //     future: fetchSellerDetails(),
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.done) {
    //         // If we got an error
    //         if (snapshot.hasError) {
    //           return Center(
    //             child: Text(
    //               '${snapshot.error} Occured',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           );
    //
    //           // if we got our data
    //         } else if (snapshot.hasData) {
    //           // Extracting data from snapshot object
    //           var data = snapshot.data;
    //           print("data is $data");
    //
    //           return Center(
    //             child: Text(
    //               'Hello',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           );
    //         }
    //       }
    //       return shimmer();
    //     });
  }

  Widget getHeading(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headline6!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.fontColor,
          ),
    );
  }

  Widget getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_outlined,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
