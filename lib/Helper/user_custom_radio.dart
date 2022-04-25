import 'package:eshop_multivendor/Model/User.dart';

import 'package:flutter/material.dart';

import 'Color.dart';
import 'Session.dart';

class RadioItem extends StatelessWidget {
  final RadioModel _item;

  const RadioItem(this._item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _item.addItem!.isDefault == '1'
          ? Theme.of(context).colorScheme.white
          : Theme.of(context).disabledColor.withOpacity(0.1),
      elevation: _item.addItem!.isDefault == '1' ? 5 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              children: <Widget>[
                _item.show
                    ? Container(
                        height: 20.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _item.isSelected!
                                ? colors.primary
                                : Theme.of(context).colorScheme.white,
                            border: Border.all(color: colors.primary)),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: _item.isSelected!
                              ? const Icon(
                                  Icons.check,
                                  size: 15.0,
                                  color: colors.whiteTemp,
                                )
                              : Icon(
                                  Icons.circle,
                                  size: 15.0,
                                  color: Theme.of(context).colorScheme.white,
                                ),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(start: 10.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _item.onSetDefault!();
                          },
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _item.name!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(_item.add!),
                          /*    Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: const [
                                    *//*InkWell(
                                      onTap: () {
                                        _item.onSetDefault!();
                                      },
                                      child: Container(
                                        height: 20.0,
                                        width: 20.0,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: _item.addItem!.isDefault == '1'
                                                ? colors.primary
                                                : Theme.of(context)
                                                .colorScheme
                                                .white,
                                            border:
                                            Border.all(color: colors.primary)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: _item.addItem!.isDefault == '1'
                                              ? const Icon(
                                            Icons.check,
                                            size: 15.0,
                                            color: colors.whiteTemp,
                                          )
                                              : Container(),
                                        ),
                                      ),
                                    ),*//*
                                    *//*Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                            start: 20),
                                        child: InkWell(
                                          onTap: () {
                                            if (_item.addItem!.isDefault == '0') {
                                              _item.onSetDefault!();
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(4.0))),
                                            child: _item.addItem!.isDefault == '0'
                                                ? Text(
                                              getTranslated(
                                                  context, 'SET_DEFAULT')!,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                              ),
                                            )
                                                : Text(
                                              getTranslated(
                                                  context, 'MARKED_DEFAULT')!,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),*//*
                                    *//*Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 20),
                                  child: InkWell(
                                    onTap: () {
                                      _item.onDeleteSelected!();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: colors.primary,
                                          width: 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Text(
                                        getTranslated(context, 'DELETE')!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),*//*
                                  ],
                                ),
                              ),*/
                            ],
                          ),
                        ),
                        Row(
                          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: (){

                                _item.onEditSelected!();
                              },
                              child: Text(
                                getTranslated(context, 'EDIT')!,
                                style: const TextStyle(
                                  color: colors.primary,
                                ),
                              ),
                            ),

                            const VerticalDivider(thickness: 5),
                            GestureDetector(
                              onTap: (){
                                _item.onDeleteSelected!();
                              },
                              child: Text(
                                getTranslated(context, 'DELETE')!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadioModel {
  bool? isSelected;
  final String? add;
  final String? name;
  final User? addItem;
  final VoidCallback? onEditSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onSetDefault;
  final show;

  RadioModel({
    this.isSelected,
    this.name,
    this.add,
    this.addItem,
    this.onEditSelected,
    this.onSetDefault,
    this.show,
    this.onDeleteSelected,
  });
}
