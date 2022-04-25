import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:flutter/cupertino.dart';

class ProductDetailProvider extends ChangeNotifier {
  final bool _reviewLoading = true;
  bool _moreProductLoading = true;
  bool _listType = true;

  final List<Product> _compareList = [];

  get compareList => _compareList;

  get listType => _listType;

  get moreProductLoading => _moreProductLoading;

  get reviewLoading => _reviewLoading;

  setReviewLoading(bool loading) {
    _moreProductLoading = loading;
    notifyListeners();
  }

  setListType(bool listType) {
    _listType = listType;
    notifyListeners();
  }

  setProductLoading(bool loading) {
    _moreProductLoading = loading;
    notifyListeners();
  }

  addCompareList(Product compareList) {
    _compareList.add(compareList);
    notifyListeners();
  }
}
