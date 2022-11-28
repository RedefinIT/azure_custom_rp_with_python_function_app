########## Script for deploying Managed App to Azure ##########

managedAppDefRG="JIO_BMCRP_DEF_RG"
storageName="jiobmcrpstorageaccount"
storageContainer="jiobmcrpstoragecontainer"
subscriptionID="8ff72bf9-c340-4810-9c89-e5a281580228"
user="GovindAvireddi@RedefinITTechnologiesPvtLtd.onmicrosoft.com"
# applicationGroup="jio_bmcrp_app_rg"
BMInstancesManagedAppDefinition="JIOBMCustomResourceDef22"
managedAppRG="demo19741003"

# Create app.zip bundling JSON files
zip app.zip createUiDefinition.json mainTemplate.json viewDefinition.json


cd ../customResourceProvider
rm artifacts/function.zip
zip -r artifacts/function.zip HttpTrigger* -x HttpTrigger*/__pycache__/\*
zip artifacts/function.zip host.json
# zip -r artifacts/function.zip .venv
zip artifacts/function.zip requirements.txt
cd -

az login

# Get Azure location for "South India"
# location=$(az account list-locations -o tsv | grep "West India" | awk -F '\t' '{ print $4 }')
location="eastus"
echo $location

# Select subscription if you have multiple subscription in the Azure account
az account set --subscription $subscriptionID

# Create resource group for managed application definition and application package
az group create --name $managedAppDefRG --location $location

# Create storage account for a package with application artifacts
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
    --public-access blob


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

# Get object ID of your identity
userid=$(az ad user show --id $user --query id --output tsv)
echo $userid
# Get role definition ID for the Owner role
roleid=$(az role definition list --name Owner --query [].name --output tsv)
echo $roleid


# Output:
# [govind@ml30gen9 managedAppWithCustomResource]$ echo $blob
# https://jio1mystorageaccount2022.blob.core.windows.net/appcontainer/app.zip

# Create resource group for managed application instance
# az group create --name $managedAppDefRG --location $location

# Create managed application definition 
az managedapp definition create \
  --name $BMInstancesManagedAppDefinition \
  --location $location \
  --resource-group $managedAppDefRG \
  --lock-level ReadOnly \
  --display-name "JIO Baremetal Instances - POC v41" \
  --description "Extends Azure Resource Manager to add bare-metal resources from on-premises datacenter into the user specified subscription and resource group" \
  --authorizations "$userid:$roleid" \
  --package-file-uri $blob

az managedapp definition update \
  --name $BMInstancesManagedAppDefinition \
  --location $location \
  --resource-group $managedAppDefRG \
  --lock-level ReadOnly \
  --display-name "JIO Baremetal Instances - POC v41" \
  --description "Extends Azure Resource Manager to add bare-metal resources from on-premises datacenter into the user specified subscription and resource group" \
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





https://redefinitbma2.azurewebsites.net/api/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.CustomProviders/resourceproviders/{minirpname}/servers/{resource_name}?

[concat('https://', variables('funcname'), '.azurewebsites.net/api/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourcegroups/redefinitbma1/providers/Microsoft.CustomProviders/resourceproviders/redefinitbma1/servers')]"

https://redefinitbma2.azurewebsites.net/api/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.CustomProviders/resourceproviders/{minirpname}/action/{action}



DefaultEndpointsProtocol=https;AccountName=storage55667y;AccountKey=dCsx06vHFBu1lLgTqpZBMkRnIdmV+hxmxuHPIewIylULN+qk/htKJTMJM9KLT2AMyUIaTLrvXd3P+AStIduwYg==


{
    "status": "Failed",
    "error": {
        "code": "ApplianceDeploymentFailed",
        "message": "The operation to create appliance failed. Please check operations of deployment 'jiopocmanagedapp6' under resource group '/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/mrg-JIOBMCustomResourceDef16-20221111223250'. Error message: 'At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.'",
        "details": [
            {
                "code": "BadRequest",
                "message": "{\r\n  \"Code\": \"BadRequest\",\r\n  \"Message\": \"The parameter LinuxFxVersion has an invalid value.\",\r\n  \"Target\": null,\r\n  \"Details\": [\r\n    {\r\n      \"Message\": \"The parameter LinuxFxVersion has an invalid value.\"\r\n    },\r\n    {\r\n      \"Code\": \"BadRequest\"\r\n    },\r\n    {\r\n      \"ErrorEntity\": {\r\n        \"ExtendedCode\": \"01007\",\r\n        \"MessageTemplate\": \"The parameter {0} has an invalid value.\",\r\n        \"Parameters\": [\r\n          \"LinuxFxVersion\"\r\n        ],\r\n        \"Code\": \"BadRequest\",\r\n        \"Message\": \"The parameter LinuxFxVersion has an invalid value.\"\r\n      }\r\n    }\r\n  ],\r\n  \"Innererror\": null\r\n}"
            }
        ]
    }
}


{
	"0": {
		"id": "/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.CustomProviders/resourceproviders/demo19741003func/servers/bmserver5",
		"adminPasswordOrKey": "Password#123",
		"adminUsername": "bma",
		"authenticationType": "",
		"resourceName": "server1",
		"dnsLabelPrefix": "",
		"location": "westindia",
		"networkSecurityGroupName": "",
		"rhelOSVersion": "8.4"
	}
}

Create Resource:
url: /subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.Solutions/applications/jiopocmanagedapp20/customservers/e2465e1b-ce42-42e0-8b3a-654c309af10c?api-version=2018-09-01-preview

{
      "requests": [
        {
          "content": {
            "id": "ed460f9d-f6ba-4012-833d-a983775a6ec4",
            "name": "ed460f9d-f6ba-4012-833d-a983775a6ec4",
            "type": "servers",
            "properties": {
              "adminUsername": "adminjio",
              "authenticationType": "password",
              "adminPasswordOrKey": "Password1234",
              "baseOS": "rhel8.4",
              "hardwareProfile": "Single-CPU_128GB-RAM",
              "instanceLocation": "eastus",
              "storage": "nfs-1",
              "backup": "backupservice-1",
              "virtualNetwork": "vnet4",
              "connectionResourceGroup": "rg1",
              "newOrExisting": "new"
            }
          },
          "httpMethod": "PUT",
          "name": "f44390e7-d2ac-44f6-b095-e9261f0d7009",
          "requestHeaderDetails": { "commandName": "Microsoft_Azure_Appliance.AddCustomResource" },
          "url": "/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.Solutions/applications/jiopocmanagedapp23/customservers/ed460f9d-f6ba-4012-833d-a983775a6ec4?api-version=2018-09-01-preview"
        }
      ]
    }


Get All Resources
url: https://management.azure.com/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.Solutions/applications/jiopocmanagedapp20/customservers?api-version=2018-09-01-preview

Action:
url: https://management.azure.com/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.Solutions/applications/jiopocmanagedapp20/custom/ping?api-version=2018-09-01-preview

{
      "requests": [
        {
          "httpMethod": "POST",
          "name": "f44390e7-d2ac-44f6-b095-e9261f0d700c",
          "requestHeaderDetails": { "commandName": "Microsoft_Azure_Appliance.overview_/ping_0" },
          "url": "https://management.azure.com/subscriptions/8ff72bf9-c340-4810-9c89-e5a281580228/resourceGroups/demo19741003/providers/Microsoft.Solutions/applications/jiopocmanagedapp23/custom/ping?api-version=2018-09-01-preview"
        }
      ]
    }




{
    "status": "Failed",
    "error": {
        "code": "ApplianceProvisioningFailed",
        "message": "Deployment template validation failed: 'The resource 'Microsoft.Web/sites/redefinittest66' is not defined in the template. Please see https://aka.ms/arm-template for usage details.'.",
        "additionalInfo": [
            {
                "type": "TemplateViolation",
                "info": {
                    "lineNumber": 0,
                    "linePosition": 0,
                    "path": ""
                }
            }
        ]
    }
}


{  "shellProps": {    "sessionId": "4689ab0222c248a89634bbb435c0c953",    "extName": "Microsoft_Azure_CreateUIDef",    "contentName": "CreateUIDefinitionActionsBlade"  },  "error": {    "message": "f is undefined",    "error": {      "message": "f is undefined",      "name": "TypeError",      "stack": "n@https://afd.hosting.portal.azure.net/createuidef/Content/Dynamic/RcRfp_Xct4Gg.js:172:908\nn.prototype._initializeCreateUIDefinition@https://afd.hosting.portal.azure.net/createuidef/Content/Dynamic/RcRfp_Xct4Gg.js:208:2616\nn.prototype.onInitialize/<@https://afd.hosting.portal.azure.net/createuidef/Content/Dynamic/RcRfp_Xct4Gg.js:208:1501\n",      "extension": "Microsoft_Azure_CreateUIDef"    },    "code": null  }}