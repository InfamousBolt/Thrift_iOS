import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Transaction_Model.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({Key? key}) : super(key: key);

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory>
    with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  List<TransactionModel> tranList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];

  @override
  void initState() {
    getTransaction();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(getTranslated(context, 'MYTRANSACTION')!, context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : showContent()
            : noInternet(context));
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
                  getTransaction();
                } else {
                  await buttonController!.reverse();
                  setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
            await post(getWalTranApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata['error'];
          // String msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata['total']);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata['data'];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
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

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
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

  showContent() {
    return tranList.isEmpty
        ? getNoItem(context)
        : ListView.builder(
            shrinkWrap: true,
            controller: controller,
            itemCount: (offset < total) ? tranList.length + 1 : tranList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return (index == tranList.length && isLoadingmore)
                  ? const Center(child: CircularProgressIndicator())
                  : listItem(index);
            },
          );
  }

  listItem(int index) {
    Color back;
    if (tranList[index].status!.toLowerCase().contains('success')) {
      back = Colors.green;
    } else if (tranList[index].status!.toLowerCase().contains('failure')) {
      back = Colors.red;
    } else {
      back = Colors.orange;
    }
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                  width: 0.5,
                  color: Theme.of(context).disabledColor,
                  style: BorderStyle.solid)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        getTranslated(context, 'AMOUNT')! +
                            ' : ${getPriceFormat(context,double.parse(tranList[index].amt!))!}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(tranList[index].date!),
                  ],
                ),
                const Divider(thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Text(getTranslated(context, 'ORDER_ID_LBL')! +
                            ' : ' +
                            tranList[index].orderId!),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                            color: back,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4.0))),
                        child: Text(
                          capitalize(tranList[index].status!),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor),
                        ),
                      )
                    ],
                  ),
                ),
                tranList[index].type!.isNotEmpty
                    ? Text(getTranslated(context, 'PAYMENT_METHOD_LBL')! +
                        ' : ' +
                        tranList[index].type!)
                    : Container(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: tranList[index].msg!.isNotEmpty
                      ? Text(getTranslated(context, 'MSG')! +
                          ' : ' +
                          tranList[index].msg!)
                      : Container(),
                ),
                tranList[index].txnID != '' && tranList[index].txnID!.isNotEmpty
                    ? Text(getTranslated(context, 'Txn_id')! +
                        ' : ' +
                        tranList[index].txnID!)
                    : Container(),
              ]),
        ));
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            if (offset < total) getTransaction();
          });
        }
      }
    }
  }
}
