import 'dart:async';

import 'package:flutter/material.dart';

typedef ActionAdditions = List<Widget>;

class AppBarController {
  AppBarController({required this.onUpdated});
  final Function() onUpdated;
  String title = '';
  ActionAdditions actionAdditions = [];


  update({String? title, ActionAdditions? actionAdditions}) {
    this.title = title ?? this.title;
    this.actionAdditions = actionAdditions ?? this.actionAdditions;
    Timer(
        const Duration(
          milliseconds: 50,
        ), () {
      onUpdated();
    });
  }

}
