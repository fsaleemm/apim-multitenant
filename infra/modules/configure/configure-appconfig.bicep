@description('The name of the API Management service instance')
param configStoreName string

resource configStoreInstance 'Microsoft.AppConfiguration/configurationStores@2021-10-01-preview' existing = {
  name: configStoreName
}

// Tenant 1
resource Tenant1 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = {
  parent: configStoreInstance
  name: 'tenantid1'
  properties: {
    value: '''{
      "TenantCertThumbprint": "78E1BE82F683EE6D8CB9B9266FC1185AE0890C41",
      "TenantCertSubject": "C=US, ST=Illinois, L=Chicago, O=TenantOne Corp., CN=*.tenant1.com",
      "BackendUrl": "https://tenant1.backend"
}'''
    contentType: 'application/json'
  }
}

// Tenant 2
resource Tenant2 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = {
  parent: configStoreInstance
  name: 'tenantid2'
  properties: {
    value: '''{
      "TenantCertThumbprint": "78E1BE82F683EE6D8CB9B9266FC1185AE0890C42",
      "TenantCertSubject": "C=US, ST=Illinois, L=Chicago, O=TenantTwo Corp., CN=*.tenant2.com",
      "BackendUrl": "https://tenant2.backend"
}'''
    contentType: 'application/json'
  }
}
