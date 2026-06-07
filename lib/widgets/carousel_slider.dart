import 'package:flutter/material.dart';

/// Re-export shim for the carousel_slider widget.
/// The app uses the `carousel_slider` pub package directly.
/// This file exists to prevent broken import errors from legacy code.
/// Any file that imports this should instead use:
///   import 'package:carousel_slider/carousel_slider.dart';
export 'package:carousel_slider/carousel_slider.dart';
