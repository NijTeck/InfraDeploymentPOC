# Login to Azure
az login

# Deploy the Bicep template directly
az deployment sub create \
  --name "IcertisContactIntelligence-dev" \
  --location "eastus" \
  --template-file azure-ad-app-registration.bicep \
  --parameters environmentName=dev appDisplayName="Icertis Contact Intelligence SSO"