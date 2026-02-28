import 'package:flutter/material.dart';

// Placeholder utilities for FlutterFlow
class FlutterFlowUtil {
  static void log(String message) {
    print('[FlutterFlow] $message');
  }
}

extension IterableExtension<T> on Iterable<T> {
  List<Widget> divide(Widget separator) {
    if (isEmpty) return [];
    return expand((item) => [item as Widget, separator]).toList()..removeLast();
  }
}

extension ListExtension<T> on List<T> {
  List<T> addToStart(T item) {
    return [item, ...this];
  }

  List<T> addToEnd(T item) {
    return [...this, item];
  }
}
