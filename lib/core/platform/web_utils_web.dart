import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String getWindowHref() => web.window.location.href;

void replaceWindowState(String url) {
  web.window.history.replaceState(null, '', url);
}

void navigateTo(String url) {
  web.window.location.href = url;
}

/// Triggers a browser download of [bytes] as [filename].
void downloadBytes(String filename, Uint8List bytes) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
