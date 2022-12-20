@description('The name of the API Management service instance')
param apimServiceName string

@description('The Storage Account Name')
param storageAccountName string

@description('The name of the API Management service instance')
param configStoreName string

resource apimInstance 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimServiceName
}

var apimId = apimInstance.identity.principalId

// Storage Account Role Assignment - Storage Table Data Reader role
resource storageInstance 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

@description('This is the built-in Storage Table Data Reader role. ')
resource storageDataReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: storageInstance
  name: '76199698-9eea-4c19-bc75-cec21354c6b6'
}

resource roleAssignmentStorage 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageInstance
  name: guid(resourceGroup().id, apimInstance.id, storageDataReaderRoleDefinition.id)
  properties: {
    roleDefinitionId: storageDataReaderRoleDefinition.id
    principalId: apimId
    principalType: 'ServicePrincipal'
  }
}

// App Configuration Service Role Assignment - App Configuration Data Reader role
resource configStoreInstance 'Microsoft.AppConfiguration/configurationStores@2021-10-01-preview' existing = {
  name: configStoreName
}

@description('This is the built-in App Configuration Data Reader role. ')
resource appConfigDataReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: configStoreInstance
  name: '516239f1-63e1-4d78-a4de-a74fb236a071'
}

resource roleAssignmentAppConfig 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: configStoreInstance
  name: guid(resourceGroup().id, configStoreInstance.id, appConfigDataReaderRoleDefinition.id)
  properties: {
    roleDefinitionId: appConfigDataReaderRoleDefinition.id
    principalId: apimId
    principalType: 'ServicePrincipal'
  }
}
