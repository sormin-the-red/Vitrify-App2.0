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
            "PoolId": "us-east-2_koMJKMR8q",
            "AppClientId": "1ascf50gbfrk0qrqspei1shoq4",
            "Region": "us-east-2"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": ["GOOGLE", "FACEBOOK"],
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": [
                "REQUIRES_LOWERCASE",
                "REQUIRES_UPPERCASE",
                "REQUIRES_NUMBERS"
              ]
            },
            "mfaConfiguration": "OFF",
            "verificationMechanisms": ["EMAIL"],
            "OAuth": {
              "WebDomain": "vitrify-auth.auth.us-east-2.amazoncognito.com",
              "AppClientId": "1ascf50gbfrk0qrqspei1shoq4",
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
