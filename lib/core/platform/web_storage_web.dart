import 'dart:html' as html;

// amplify_auth_cognito 2.x reads this key during configure() to decide
// whether to run the OAuth session-restoration path. That path calls
// UpdateUserAttributes(email), which Cognito rejects as immutable for
// federated users. Removing the key before configure() causes the library
// to restore the session through the regular Cognito token path instead —
// the access/id/refresh tokens stay intact so the user remains signed in.
void clearHostedUiFlag() {
  html.window.localStorage.remove('amplify-signin-with-hostedUI');
}
