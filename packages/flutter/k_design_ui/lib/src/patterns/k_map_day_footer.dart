import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

Widget buildKMapDayFooter(KDesignTokens tokens, Widget child) => DecoratedBox(
  decoration: BoxDecoration(
    border: Border(top: BorderSide(color: tokens.colorBorderDefault)),
  ),
  child: SafeArea(
    top: false,
    minimum: EdgeInsets.fromLTRB(
      tokens.spaceHairline * 24,
      tokens.spaceHairline * 16,
      tokens.spaceHairline * 24,
      tokens.spaceHairline * 16,
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(
        color: tokens.colorTextPrimary,
        fontFamily: tokens.fontFamily,
        fontSize: tokens.fontBodySmallSize,
      ),
      child: child,
    ),
  ),
);
