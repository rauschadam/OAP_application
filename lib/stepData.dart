// ignore_for_file: file_names

import 'package:flutter/material.dart';

class StepData {
  final String title;
  final Widget Function() builder;
  final Future<bool> Function()? onNext;

  StepData({required this.title, required this.builder, this.onNext});
}
