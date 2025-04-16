@description('Environment name (dev or prod)')
param environmentName string

@description('Display name for the application')
param appDisplayName string

resource applicationRegistrationScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAzureAdApp-${environmentName}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.37.0'
    scriptContent: '''
      # Predefined configuration details
      appId="aacaf289-3107-4c32-86ff-5e92dfc8d44d"
      
      # Create application with specific configuration
      app=$(az ad app create \
        --display-name "${DISPLAY_NAME}" \
        --sign-in-audience AzureADMultipleOrgs \
        --identifier-uris "api://icertisOAuth")

      # Get the created application's object ID
      objectId=$(echo $app | jq -r '.id')

      # Update application with detailed configuration via Microsoft Graph
      az rest --method PATCH \
        --uri "https://graph.microsoft.com/v1.0/applications/$objectId" \
        --headers "Content-Type=application/json" \
        --body "{
          \"appId\": \"$appId\",
          \"identifierUris\": [\"api://icertisOAuth\"],
          \"oauth2Permissions\": [
            {
              \"adminConsentDescription\": \"Allows write access to the tasks API\",
              \"adminConsentDisplayName\": \"Write access to tasks API\",
              \"id\": \"f90d168b-cd31-4aba-afff-2c7dd7d98417\",
              \"isEnabled\": true,
              \"origin\": \"Application\",
              \"type\": \"Admin\",
              \"value\": \"tasks.read\"
            },
            {
              \"adminConsentDescription\": \"Allow this app to read all within it's UID\",
              \"adminConsentDisplayName\": \"readIcertis\",
              \"id\": \"caccb244-dd79-4620-8d45-d7bc51200863\",
              \"isEnabled\": true,
              \"origin\": \"Application\",
              \"type\": \"Admin\",
              \"value\": \"icertis\"
            }
          ],
          \"appRoles\": [
            {
              \"allowedMemberTypes\": [\"User\", \"Application\"],
              \"description\": \"USER\",
              \"displayName\": \"USER\",
              \"id\": \"93214733-7c8c-449f-a286-b437ee562cfc\",
              \"isEnabled\": false,
              \"origin\": \"Application\",
              \"value\": \"USER\"
            },
            {
              \"allowedMemberTypes\": [\"Application\"],
              \"description\": \"admin to the application\",
              \"displayName\": \"appAdmin\",
              \"id\": \"677c7b21-4063-4335-944c-e7eb0018c2fd\",
              \"isEnabled\": true,
              \"origin\": \"Application\",
              \"value\": \"$appId\"
            },
            {
              \"allowedMemberTypes\": [\"User\"],
              \"description\": \"msiam_access\",
              \"displayName\": \"msiam_access\",
              \"id\": \"b9632174-c057-4f7e-951b-be3adc52bfe6\",
              \"isEnabled\": true,
              \"origin\": \"Application\",
              \"value\": null
            }
          ],
          \"requiredResourceAccess\": [
            {
              \"resourceAppId\": \"$appId\",
              \"resourceAccess\": [
                {
                  \"id\": \"f90d168b-cd31-4aba-afff-2c7dd7d98417\",
                  \"type\": \"Scope\"
                }
              ]
            }
          ],
          \"parentalControlSettings\": {
            \"countriesBlockedForMinors\": [],
            \"legalAgeGroupRule\": \"Allow\"
          },
          \"oauth2AllowImplicitFlow\": true,
          \"oauth2AllowIdTokenImplicitFlow\": true,
          \"allowPublicClient\": true
        }"

      # Output application details
      echo "{\"appId\": \"$appId\", \"objectId\": \"$objectId\"}"
    '''
    environmentVariables: [
      {
        name: 'DISPLAY_NAME'
        value: '${appDisplayName}-${environmentName}'
      }
    ]
    forceUpdateTag: guid(resourceGroup().id)
    containerSettings: {
      containerGroupName: 'deploy-ad-app-${environmentName}'
    }
    timeout: 'PT10M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
}

output applicationId string = applicationRegistrationScript.properties.outputs.objectId
output applicationClientId string = applicationRegistrationScript.properties.outputs.appId
