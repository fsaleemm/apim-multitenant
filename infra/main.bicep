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


module storage './modules/storage.bicep' = {
  name: '${rg.name}-storage'
  scope: rg
  params: {
    location: rg.location
  }
}

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

module roleAssignmentAPIMTableStorageDataReader './modules/configure/roleAssign-apim-storage.bicep' = {
  name: '${rg.name}-roleAssignmentAPIMStorageAccout'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    apim
    storage
  ]
}
