import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'auth-data.dart';

/// This class contains [OAuth] data and
/// functionality. It has one public method
/// that returns a [WebView] which has been set up
/// for OAuth 2.0 Authentication.
class OAuth {
  // ignore: public_member_api_docs
  OAuth({
    required this.baseUrl,
    required this.clientID,
    required this.redirectUri,
    required this.state,
    required this.scope,
    this.responseType,
    this.otherQueryParams = const {},
  });

  final String baseUrl; // OAuth url
  final String clientID; // OAuth clientID
  final String? responseType; // OAuth clientSecret
  final String redirectUri; // OAuth redirectUri
  final String state; // OAuth state
  final String scope; // OAuth scope
  final Map<String, String> otherQueryParams;
  static const String TOKEN_KEY = 'access_token'; // OAuth token key
  static const String CODE_KEY = 'code'; // OAuth code key
  static const String STATE_KEY = 'state'; // OAuth state key
  static const String SCOPE_KEY = 'scope'; // OAuth scope key
  static const String CLIENT_ID_KEY = 'clientID'; // custom client id key
  static const String REDIRECT_URI_KEY =
      'redirectURI'; // custom redirect uri key
  final String userAgent = 'Chrome/81.0.0.0 Mobile'; // UA

  /// Sets up a [WebView] for OAuth authentication.
  /// [onDone] is called when authentication is
  /// completed successfully.
  WebView authenticate({
    required Function(AuthData) onDone,
    bool clearCache = false,
  }) {
    final responseTypeQuery = '&response_type=${responseType ?? 'token'}';
    final otherParams = StringBuffer();

    for (final key in otherQueryParams.keys) {
      otherParams.write('&$key=${otherQueryParams[key]}');
    }

    var authUrl = '$baseUrl'
        '?client_id=${Uri.encodeComponent(clientID)}'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=${Uri.encodeComponent(scope)}'
        '$responseTypeQuery'
        '$otherParams';

    return WebView(
      onWebViewCreated: (controller) async {
        if (clearCache) {
          final cookieManager = CookieManager();

          await cookieManager.clearCookies();
          await controller.clearCache();
        }
      },
      userAgent: userAgent,
      initialUrl: authUrl,
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: _getNavigationDelegate(onDone),
    );
  }

  /// Returns a navigation delegate that attempts
  /// to match the redirect url whenever the browser
  /// navigates to a new page. Once the redirect url
  /// is found, it calls the [onDone] callback.
  NavigationDecision Function(NavigationRequest request) _getNavigationDelegate(
    Function(AuthData) onDone,
  ) =>
      (request) {
        final url = request.url;
        if (url.startsWith(redirectUri)) {
          print('redirected to: $url');

          final returnedData = _getQueryParams(url);
          returnedData[CLIENT_ID_KEY] = clientID;
          returnedData[TOKEN_KEY] = clientID;
          returnedData[REDIRECT_URI_KEY] = redirectUri;
          returnedData[STATE_KEY] = state;

          final authData = AuthData(
            clientID: clientID,
            accessToken: returnedData[TOKEN_KEY],
            response: returnedData,
          );

          onDone(authData);
        }

        return NavigationDecision.navigate;
      };

  /// Parses url query params into a map
  /// @param url: The url to parse.
  Map<String, String> _getQueryParams(String url) {
    final urlParams = url.split(RegExp('[?&# ]'));
    final Map<String, String> queryParams = HashMap();
    List<String> parts;

    for (final param in urlParams) {
      if (param.contains('=')) {
        parts = param.split('=');
        queryParams[parts[0]] = Uri.decodeFull(parts[1]);
      }
    }

    return queryParams;
  }
}
