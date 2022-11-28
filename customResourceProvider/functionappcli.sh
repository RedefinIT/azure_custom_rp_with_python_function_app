########## Script for deploying Managed App to Azure ##########

functionAppRG="redefinitFunctionAppRG"
functionAppName="redefinitfunctionapp2022"
appServicePlan="ASP-"$functionAppName
storageName="functionappstorage5675"
storageContainer="jiobmcrpstoragecontainer"


az login

# Select subscription if you have multiple subscription in the Azure account
az account set --subscription $subscriptionID

# Get Azure location for "South India"
# location=$(az account list-locations -o tsv | grep "West India" | awk -F '\t' '{ print $4 }')
location="eastus"
echo $location

# Create resource group for managed application definition and application package
az group create --name $functionAppRG --location $location

# Create storage account for a package with application artifacts
az storage account create --name $storageName --resource-group $functionAppRG --location $location --sku Standard_LRS --kind StorageV2

# Create App service plan for the function app.
az appservice plan create --name $appServicePlan --resource-group $functionAppRG  --is-linux --number-of-workers 1

appServicePlanID=$(az appservice plan show --name $appServicePlan --resource-group $functionAppRG --output tsv | awk -F '\t' '{ print $1 }')

# Create Function App
az functionapp create -n $functionAppName -g $functionAppRG --os-type Linux --plan $appServicePlanID \
--storage-account $storageName --runtime "Python" --functions-version 4 --runtime-version 3.9

rm artifacts/function.zip
zip -r artifacts/function.zip HttpTrigger* -x HttpTrigger*/__pycache__/\*
zip artifacts/function.zip host.json
# zip -r artifacts/function.zip .venv
zip artifacts/function.zip requirements.txt


# Create storage container and upload zip to blob
az storage container create \
    --account-name $storageName \
    --name $storageContainer \
    --public-access blob


# Upload function app package to Azure storage container
az storage blob upload \
    --account-name $storageName \
    --container-name $storageContainer \
    --overwrite \
    --name "function.zip" \
    --file "../customResourceProvider/artifacts/function.zip"

# Get URL for function app package
functionBlob=$(az storage blob url \
  --account-name $storageName \
  --container-name $storageContainer \
  --name function.zip --output tsv  --auth-mode login)
echo $functionBlob


# Deploy the function app
az functionapp deploy --name $functionAppName --type zip --src-url $functionBlob --restart true --resource-grou $functionAppRG


