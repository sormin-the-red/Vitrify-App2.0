import 'dart:typed_data';

String getWindowHref() => '';
void replaceWindowState(String url) {}
void navigateTo(String url) {}

/// No-op on non-web platforms — callers share via share_plus instead.
void downloadBytes(String filename, Uint8List bytes) {}
