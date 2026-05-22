const amplifyConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/cognito",
        "Version": "0.1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-2_Xl7aqCbu8",
            "AppClientId": "4crvqr5tft9e4i5d64k2rt1r4e",
            "Region": "us-east-2"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "OAuth": {
              "WebDomain": "glazevault-auth.auth.us-east-2.amazoncognito.com",
              "AppClientId": "4crvqr5tft9e4i5d64k2rt1r4e",
              "SignInRedirectURI": "vitrify://callback,http://localhost:3000/",
              "SignOutRedirectURI": "vitrify://logout,http://localhost:3000/",
              "Scopes": ["email", "openid", "profile"]
            }
          }
        }
      }
    }
  }
}
''';
