// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String getWindowHref() => html.window.location.href;

void replaceWindowState(String url) {
  html.window.history.replaceState(null, '', url);
}

void navigateTo(String url) {
  html.window.location.href = url;
}
