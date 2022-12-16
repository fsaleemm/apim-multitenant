@description('The name of the API Management service instance')
param apimServiceName string

@description('The Storage Account Name')
param storageAccountName string

resource apimInstance 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimServiceName
}

var apimId = apimInstance.identity.principalId

resource storageInstance 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

@description('This is the built-in Storage Table Data Reader role. ')
resource storageDataReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: storageInstance
  name: '76199698-9eea-4c19-bc75-cec21354c6b6'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageInstance
  name: guid(resourceGroup().id, apimInstance.id, storageDataReaderRoleDefinition.id)
  properties: {
    roleDefinitionId: storageDataReaderRoleDefinition.id
    principalId: apimId
    principalType: 'ServicePrincipal'
  }
}
