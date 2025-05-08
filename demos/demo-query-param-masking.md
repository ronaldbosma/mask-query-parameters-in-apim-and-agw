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
