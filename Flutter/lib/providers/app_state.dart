import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _showSpinner = false;

  bool get showSpinner => _showSpinner;

  void setSpinnerVisibility(bool visibility) {
    _showSpinner = visibility;
    notifyListeners();
  }
}
