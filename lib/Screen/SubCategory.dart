import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'ProductList.dart';

class SubCategory extends StatelessWidget {
  final List<Product>? subList;
  final String title;
  const SubCategory({Key? key, this.subList, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(title, context),
      body: Center(
        child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: .75,
            children: List.generate(
              subList!.length,
              (index) {
                return subCatItem(index, context);
              },
            )),
      ),
    );
  }

  subCatItem(int index, BuildContext context) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                    image: CachedNetworkImageProvider(subList![index].image!),
                    fadeInDuration: const Duration(milliseconds: 150),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                    placeholder: placeHolder(50),
                  )),
            ),
          ),
          Text(
            subList![index].name! + '\n',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {
        if (subList![index].subList == null ||
            subList![index].subList!.isEmpty) {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ProductList(
                  name: subList![index].name,
                  id: subList![index].id,
                  tag: false,
                  fromSeller: false,
                ),
              ));
        } else {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => SubCategory(
                  subList: subList![index].subList,
                  title: subList![index].name ?? '',
                ),
              ));
        }
      },
    );
  }
}
