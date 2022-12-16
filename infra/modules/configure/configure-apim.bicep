@description('The name of the API Management service instance')
param apimServiceName string

resource apimInstance 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apimServiceName
}

resource api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'get-config-cached'
  parent: apimInstance
  properties: {
    displayName: 'Get Configuration Cached'
    path: 'get-config-cached'
    apiType: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource apiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'tenant-data'
  parent: api
  properties:{
    displayName: 'Tenant Data'
    method: 'GET'
    urlTemplate: '/tenantdata'
    request: {
      queryParameters: [
        {
          name: 'uid'
          type: 'string'
          required: true
        }
        {
          name: 'storagetableurl'
          type: 'string'
          required: true
        }
      ]
    }
  }
}

resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name:'policy'
  parent: apiOperation
  properties: {
    format: 'rawxml'
    value: '<policies>     <inbound>         <base />         <!-- Get the query parameters and create variable context -->         <set-variable name="tenantid" value="@(context.Request.Url.Query.GetValueOrDefault("uid", ""))" />         <set-variable name="storageTableUrl" value="@(context.Request.Url.Query.GetValueOrDefault("storagetableurl", ""))" />         <!-- Look up internal cache for this tenant id (customer) -->         <cache-lookup-value key="@("tenantdata-" + context.Variables["tenantid"])" variable-name="tenantdata" />         <choose>             <when condition="@(!context.Variables.ContainsKey("tenantdata"))">                 <!-- If the tenantdata context variable does not exist, make an HTTP request to retrieve it from Table Storage.  -->                 <send-request mode="new" response-variable-name="tenantdataresponse" timeout="20" ignore-error="false">                     <set-url>@{                             return String.Format("{0}(PartitionKey=\'1\',RowKey=\'{1}\')", context.Variables["storageTableUrl"], context.Variables["tenantid"]);                         }</set-url>                     <set-method>GET</set-method>                     <set-header name="x-ms-date" exists-action="override">                         <value>@(TimeZoneInfo.ConvertTimeToUtc(DateTime.Now).ToString("R"))</value>                     </set-header>                     <set-header name="x-ms-version" exists-action="override">                         <value>2020-04-08</value>                     </set-header>                     <set-header name="Accept" exists-action="override">                         <value>application/json;odata=nometadata</value>                     </set-header>                     <authentication-managed-identity resource="https://storage.azure.com" />                 </send-request>                 <set-variable name="tenantdata" value="@(((IResponse)context.Variables["tenantdataresponse"]).Body.As<JObject>())" />                 <!-- Store the response data to internal cache -->                 <cache-store-value key="@("tenantdata-" + context.Variables["tenantid"])" value="@((JObject)context.Variables["tenantdata"])" duration="120" />             </when>         </choose>         <!--             Continue with request, for example:                 Add validate-client-certificate policy and use the thumbprint for validation.                 If certificate is valid, then use the backend url to send request to appropriate backend for this tenant.                         For this tutorial purposes, we are just displaying the tenant data in the response.         -->         <return-response>             <set-status code="200" />             <set-body template="none">@(((JObject)context.Variables["tenantdata"]).ToString())</set-body>         </return-response>     </inbound>     <backend>         <base />     </backend>     <outbound>         <base />     </outbound>     <on-error>         <base />     </on-error> </policies>'
  }
}
