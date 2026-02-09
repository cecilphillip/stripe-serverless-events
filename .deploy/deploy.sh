deploymentName=StripeServerless
resourceGroupName=AzStripeDemo

# az deployment sub delete --name $deploymentName --resource-group $resourceGroupName
az deployment sub create --location 'eastus' --template-file main.bicep --parameters resourceGroupName=$resourceGroupName -n $deploymentName --output jsonc