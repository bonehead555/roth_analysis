import 'package:flutter/material.dart';

class WidgetConstants {
  //static const edgeInsetsTop = EdgeInsets.only(top: 16.0, bottom: 0.0);
  //static const edgeInsetsMiddle = EdgeInsets.only(top: 8.0, bottom: 0.0);
  static const defaultTextFieldPadding = EdgeInsets.only(top: 8.0, bottom: 0.0);
  static const defaultOtherFieldPadding =
      EdgeInsets.only(top: 8.0, bottom: 20.0);
  static const defaultDivider = Padding(
    padding: EdgeInsets.only(bottom: 6.0),
    child: Divider(
      thickness: 2,
      height: 5.0,
    ),
  );
  static const double fieldHeight = 65;
  static String fieldIsInvalidMsg = 'Invalid fields must be fixed!';
}
