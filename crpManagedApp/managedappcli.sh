########## Script for deploying Managed App to Azure ##########

managedAppDefRG="managedAppDefRG"
subscriptionID=<YOUR SUBSCRIPTION ID>
user=<YOUR USER NAME>
managedAppRG="managedAppRG"
functionAppName="redefinitfunctionapp2022"

# Create app.zip bundling JSON files
zip app.zip createUiDefinition.json mainTemplate.json viewDefinition.json

az login

# Azure location 
# location=$(az account list-locations -o tsv | grep "West India" | awk -F '\t' '{ print $4 }')
location="eastus"
echo $location

# Select subscription if you have multiple subscription in the Azure account
az account set --subscription $subscriptionID

# Create resource group for managed application definition and application package
az group create --name $managedAppDefRG --location $location

# Create storage account for a package with application artifacts
storageName=<GLOBALLY UNIQUE NAME>
storageContainer="manageappcontainer"
az storage account create \
    --name $storageName \
    --resource-group $managedAppDefRG \
    --location $location \
    --sku Standard_LRS \
    --kind StorageV2

# Create storage container and upload zip to blob
az storage container create \
    --account-name $storageName \
    --name $storageContainer \
    --public-access blob \
    --auth-mode login

# Upload customer resource templates to Azure storage container
az storage blob upload \
    --account-name $storageName \
    --container-name $storageContainer \
    --overwrite \
    --name "app.zip" \
    --file "./app.zip"

# Get URL for custom resource provider templates
blob=$(az storage blob url \
  --account-name $storageName \
  --container-name $storageContainer \
  --name app.zip --output tsv  --auth-mode login)
echo $blob

# Get object ID of your identity
userid=$(az ad user show --id $user --query id --output tsv)
echo $userid
# Get role definition ID for the Owner role
roleid=$(az role definition list --name Owner --query [].name --output tsv)
echo $roleid


# Create resource group for managed application instance
# az group create --name $managedAppDefRG --location $location

# Create managed application definition 
az managedapp definition create \
  --name "crpManagedApp1" \
  --location $location \
  --resource-group $managedAppDefRG \
  --lock-level ReadOnly \
  --display-name "Custom Resources Managed App 1" \
  --description "Extends Azure Resource Manager to add custom resources" \
  --authorizations "$userid:$roleid" \
  --package-file-uri $blob

az managedapp definition update \
  --name "crpManagedApp1" \
  --location $location \
  --resource-group $managedAppDefRG \
  --lock-level ReadOnly \
  --display-name "Custom Resources Managed App 1.4" \
  --description "Extends Azure Resource Manager to add custom resources" \
  --authorizations "$userid:$roleid" \
  --package-file-uri $blob

