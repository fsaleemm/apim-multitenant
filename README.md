# Azure API Management - Multi-tenant Solutions

This tutorial will illustrate the use of APIM to integrate with multiple integration in a multi-tenant scenarios. For example, having to pick the appropriate backend API based on the tenant customer id, or to validate the client request based on client certificate in mTLS authentication setup for multiple clients.

## Concepts 

The following general concepts will be demonstrated:
1. Use of [managed identities to authenticate API Management](https://learn.microsoft.com/en-us/azure/api-management/api-management-authentication-policies#ManagedIdentity) to other Azure Services (Azure Storage Table).
1. Use of [send-request APIM policy](https://learn.microsoft.com/en-us/azure/api-management/api-management-advanced-policies#SendRequest).
1. Use of internal cache with APIM and [caching policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-caching-policies).

The components used to illustrate this solution are:
1. Azure API Management
1. Azure Storage Account (Table)

## Demo Diagram

![Conceptual View](/media/s1.png)

In the above diagram the request flow is as follows:
1. A request from a specific tenant (Tenant 1) is received by APIM
1. The APIM policy is configured to do the following:
    1. Check the internal cache for tenant data.
    1. If there is a cache miss, go to table storage and get tenant data.
    1. Cache the tenant data for subsequent requests.
    1. Process the request, for example, a tenant specific backend API can be used to forward the request. Or to validate the client request using [validate-client-certificate policy](https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#validate-client-certificate) and validate the client certificate.
1. For this illustration we will simply display the tenant data.

This concept can be expanded to connect with other configuration sources such as:
1. Azure App Configuration Service.
1. Azure Key Vault Service.
1. Other Azure Managed storage options, Cosmos DB, SQL Database etc.

## Policy Definition

```xml
<policies>
    <inbound>
        <base />
        <!-- Get the query parameters and create variable context -->
        <set-variable name="tenantid" value="@(context.Request.Url.Query.GetValueOrDefault("uid", ""))" />
        <set-variable name="storageTableUrl" value="@(context.Request.Url.Query.GetValueOrDefault("storagetableurl", ""))" />

        <!-- Look up internal cache for this tenant id (customer) -->
        <cache-lookup-value key="@("tenantdata-" + context.Variables["tenantid"])" variable-name="tenantdata" />

        <choose>
            <when condition="@(!context.Variables.ContainsKey("tenantdata"))">

                <!-- If the tenantdata context variable doesn’t exist, make an HTTP request to retrieve it from Table Storage.  -->
                <send-request mode="new" response-variable-name="tenantdataresponse" timeout="20" ignore-error="false">
                    <set-url>@{
                            return String.Format("{0}(PartitionKey='1',RowKey='{1}')", context.Variables["storageTableUrl"], context.Variables["tenantid"]);
                        }</set-url>
                    <set-method>GET</set-method>
                    <set-header name="x-ms-date" exists-action="override">
                        <value>@(TimeZoneInfo.ConvertTimeToUtc(DateTime.Now).ToString("R"))</value>
                    </set-header>
                    <set-header name="x-ms-version" exists-action="override">
                        <value>2020-04-08</value>
                    </set-header>
                    <set-header name="Accept" exists-action="override">
                        <value>application/json;odata=nometadata</value>
                    </set-header>
                    <authentication-managed-identity resource="https://storage.azure.com" />
                </send-request>

                <set-variable name="tenantdata" value="@(((IResponse)context.Variables["tenantdataresponse"]).Body.As<JObject>())" />

                <!-- Store the response data to internal cache -->
                <cache-store-value key="@("tenantdata-" + context.Variables["tenantid"])" value="@((JObject)context.Variables["tenantdata"])" duration="120" />
            </when>
        </choose>
        <!--
            Continue with request, for example:
                Add validate-client-certificate policy and use the thumbprint for validation.
                If certificate is valid, then use the backend url to send request to appropriate backend for this tenant.
            
            For this tutorial purposes, we are just displaying the tenant data in the response.
        -->
        <return-response>
            <set-status code="200" />
            <set-body template="none">@(((JObject)context.Variables["tenantdata"]).ToString())</set-body>
        </return-response>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>

```

## Demo Setup

Login to your Azure in your terminal.

```bash
az login
```

To check your subscription.

```bash
az account show
```

Run the deployment. The deployment will create the resource group "rg-\<Name suffix for resources\>". Make sure you are in the 'apim-multitenant' directory.

```bash
cd apim-multitenant

az deployment sub create --name "<unique deployment name>" --location "<Your Chosen Location>" --template-file infra/main.bicep --parameters name="<Name suffix for resources>" publisherEmail="<Publisher Email for APIM>" publisherName="<Publisher Name for APIM>" 
```

The following deployments will run:

![deployment times](media/s2.png)

>**NOTE**: The APIM deployment can take over an hour to complete.


