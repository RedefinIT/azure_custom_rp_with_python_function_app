########## Script for deploying Managed App to Azure ##########

managedAppDefRG="managedAppDefRG"
subscriptionID="8ff72bf9-c340-4810-9c89-e5a281580228"
user="GovindAvireddi@RedefinITTechnologiesPvtLtd.onmicrosoft.com"
BMInstancesManagedAppDefinition="JIOBMCustomResourceDef22"
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
storageName="globalunique193344"
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
  --display-name "Custom Resources Managed App 1" \
  --description "Extends Azure Resource Manager to add custom resources" \
  --authorizations "$userid:$roleid" \
  --package-file-uri $blob




# az deployment group create \
#   --name functionAppDeployment \
#   --resource-group ExampleGroup \
#   --template-file ./customResourceProvider/azuredeploy.json \
#   --parameters storageAccountType=Standard_GRS

# managed_rg="managedrg1"
managed_rg="mgr-"$BMInstancesManagedAppDefinition"-1124"
# az group create --name $managed_rg --location $location
# managed_rg_id=$(az group show --name $managed_rg --output tsv --query id)

managed_rg_id="/subscriptions/"$subscriptionID"/resourceGroups/"$managed_rg
echo $managed_rg_id

# Get ID of managed application definition
appid=$(az managedapp definition show --name $BMInstancesManagedAppDefinition --resource-group $managedAppDefRG --query id --output tsv)
echo $appid


# Create resource group for managed application instance
az group create --name $managedAppRG --location $location

# Create the managed application
az managedapp create \
  --name "JIO1BMManagedAppJIO_4" \
  --location $location \
  --kind "Servicecatalog" \
  --resource-group $managedAppRG \
  --managedapp-definition-id $appid \
  --managed-rg-id $managed_rg_id \
  --parameters "{\"adminUsername\": {\"value\": \"admin\"}}"


# Create custom resource
az resource create


az resource invoke-action --action myCustomAction \
                          --ids /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomProviders/resourceProviders/myCustomProvider \
                          --request-body '{"hello": "world"}'

az resource invoke-action --action myCustomAction \
                          --ids /subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/jiopoc1/providers/Microsoft.CustomProviders/resourceProviders/bmafunctionapp1211/bma \
                          --request-body '{ "hello": "world"}'



az logout





{
    "status": "Failed",
    "error": {
        "code": "ApplianceDeploymentFailed",
        "message": "The operation to create appliance failed. Please check operations of deployment 'te3stg2334' under resource group '/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/mrg-crpManagedApp1-20221128215321'. Error message: 'At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.'",
        "details": [
            {
                "code": "Conflict",
                "message": "{\r\n  \"status\": \"Failed\",\r\n  \"error\": {\r\n    \"code\": \"ResourceDeploymentFailure\",\r\n    \"message\": \"The resource operation completed with terminal provisioning state 'Failed'.\",\r\n    \"details\": [\r\n      {\r\n        \"code\": \"InvalidRouteDefinitionHostName\",\r\n        \"message\": \"The resource provider 'public' route definition 'horses' endpoint has a host name 'uniquefunctionname121.azurewebsites.net', which could not be resolved. Please double check that the host name is externally resolvable.\"\r\n      }\r\n    ]\r\n  }\r\n}"
            }
        ]
    }
}