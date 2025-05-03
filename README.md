# Mask query parameters in Azure API Management and Application Gateway


Kusto query to retrieved logged API Management requests.

```kusto
requests
| where customDimensions["Service Type"] == "API Management"
| extend subscription = tostring(customDimensions["Subscription Name"])
| project timestamp, subscription, url
| sort by timestamp desc
```