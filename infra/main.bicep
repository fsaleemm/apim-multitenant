targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
}

// Deploy APIM Instance
module apim './modules/apim.bicep' = {
  name: '${rg.name}-apim'
  scope: rg
  params: {
    apimServiceName: 'apim-${toLower(name)}'
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: rg.location
  }
}

// Configure APIM instance with APIs and policies
module configurAPIM './modules/configure/configure-apim.bicep' = {
  name: '${rg.name}-configureAPIM'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
  }
  dependsOn: [
    apim
  ]
}


// Deploy App Configuration instance
module appconfig './modules/appconfig.bicep' = {
  name: '${rg.name}-appconfig'
  scope: rg
  params: {
    configStoreName: 'appconfig-${toLower(name)}'
    location: rg.location
  }
}

// Configure sample tenant data configurations
module configurAppConfig './modules/configure/configure-appconfig.bicep' = {
  name: '${rg.name}-configureAppConfig'
  scope: rg
  params: {
    configStoreName: appconfig.outputs.appConfigServiceName
  }
  dependsOn: [
    appconfig
  ]
}

// Deploy Storage Account instance
module storage './modules/storage.bicep' = {
  name: '${rg.name}-storage'
  scope: rg
  params: {
    location: rg.location
  }
}

// Configure storage account with table storage for tenant data
module configureStorageAccount './modules/configure/configure-storage.bicep' = {
  name: '${rg.name}-configureStorageAccount'
  scope: rg
  params: {
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    storage
  ]
}

// Configure role assignment for APIM to read data from App Config and Table Storage
module roleAssignmentAPIM './modules/configure/roleAssign-apim.bicep' = {
  name: '${rg.name}-roleAssignmentAPIM'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    storageAccountName: storage.outputs.storageAccountName
    configStoreName: appconfig.outputs.appConfigServiceName
  }
  dependsOn: [
    apim
    storage
    appconfig
  ]
}
