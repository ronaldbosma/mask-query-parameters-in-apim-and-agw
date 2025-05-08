# Demo Query Parameter Masking

In this demo scenario, you will demonstrate how to mask sensitive query parameters in a URL. This is useful for protecting sensitive information such as API keys, tokens, or personal data from being exposed in logs.

## 1. What resources are getting deployed

The following resources will be deployed:

![Deployed Resources](/images/deployed-resources.png)


## 2. What can I demo from this scenario after deployment

### Send test requests

You can send requests directly to API Management and through the Application Gateway. 
The requests will be logged in the Log Analytics Workspace.
The [tests.http](/tests/tests.http) file contains a set of HTTP requests that you can use for this purpose.

Follow these steps to send the requests using Visual Studio Code:

1. Install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension in Visual Studio Code. 

1. The API is protected and needs to be called with a subscription key. 
   Locate the `Built-in all-access` subscription in API Management and copy the primary key.

1. Add an environment to your Visual Studio Code user settings with the Application Gateway public IP address, API Management hostname and subscription key. 
   Use the following example and replace the values with your own:
   ```
   "rest-client.environmentVariables": {
       "maskqueryparam": {
           "agwIPAddress": "123.456.78.90",
           "apimHostname": "apim-maskqueryparams-nwe-kt2tx.azure-api.net",
           "apimSubscriptionKey": "1234567890abcdefghijklmnopqrstuv"
       }
   }
   ```

1. Open [tests.http](/tests/tests.http) and at the bottom right of the editor, select the `maskqueryparam` environment you just configured.

1. Click on `Send Request` above the requests. This will call the Echo API with the subscription key as a query parameter.

### Review the logs

After sending the requests, you can review the logs in the Log Analytics Workspace. It might take a few minutes for the logs to appear.

To review the logs, open the Log Analytics Workspace in the Azure portal and select `Logs` in the left menu.

#### Application Gateway - Access Log

You can use the following query to see the requests that were logged in the Application Gateway Access Log.

```kusto
AzureDiagnostics
| where ResourceType == 'APPLICATIONGATEWAYS'
| where Category == 'ApplicationGatewayAccessLog'
| project TimeGenerated, originalRequestUriWithArgs_s
```

If you encounter the error below, it means that no logs have been generated yet. 
The `originalRequestUriWithArgs_s` column will only appear after the first request has been logged.

```
'project' operator: Failed to resolve scalar expression named 'originalRequestUriWithArgs_s'
```


#### Application Gateway - Firewall Log

You can use the following query to see the requests that were logged in the Application Gateway Firewall Log.

```kusto
AzureDiagnostics
| where ResourceType == 'APPLICATIONGATEWAYS'
| where Category == 'ApplicationGatewayFirewallLog'
// we use distinct because multiple records for a single request are logged
| distinct TimeGenerated, requestUri_s
```

#### API Management - Requests

You can use the following query to see the requests that were sent to the API Management service.

```kusto
AppRequests 
| where Properties["Service Type"] == "API Management"
| extend Subscription = tostring(Properties["Subscription Name"])
| project TimeGenerated, Subscription, Url
```

#### API Management - Gateway Log

You can use the following query to see the requests that were logged in the API Management Gateway Log.
Note that no results will be returned if you deployed a Consumption tier API Management instance, as this tier doesn't support logging to the API Management Gateway Log. 
See the [README](/README.md) for more information.

```kusto
AzureDiagnostics
| where ResourceType == 'SERVICE'
| where Category == 'GatewayLogs'
| project TimeGenerated, url_s, requestUri_s
```