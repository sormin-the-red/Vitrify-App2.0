// TODO: Replace placeholder values with CDK deploy outputs.
// After running `cdk deploy` from vitrify-backend/infra/, copy:
//   UserPoolId       → PoolId
//   UserPoolClientId → AppClientId (both spots)
//   Cognito domain   → WebDomain  (set up a domain in the Cognito console first)
const amplifyConfig = '''
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "REPLACE_WITH_USER_POOL_ID",
            "AppClientId": "REPLACE_WITH_APP_CLIENT_ID",
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
            "oauth": {
              "WebDomain": "REPLACE_WITH_COGNITO_DOMAIN",
              "AppClientId": "REPLACE_WITH_APP_CLIENT_ID",
              "SignInRedirectURI": "vitrify://callback",
              "SignOutRedirectURI": "vitrify://logout",
              "Scopes": ["email", "openid", "profile"]
            }
          }
        }
      }
    }
  }
}
''';
