@description('The name of the API Management service instance')
param storageAccountName string

resource storageInstance 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}


resource TableService 'Microsoft.Storage/storageAccounts/tableServices@2022-05-01' = {
  name: 'default'
  parent: storageInstance
}

resource TenatMappingTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-05-01' = {
  name: 'TenantMapping'
  parent: TableService
}
