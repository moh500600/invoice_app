// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebStorage {
  static String? getItem(String key) => html.window.localStorage[key];
  static void setItem(String key, String value) {
    html.window.localStorage[key] = value;
  }
}

