# Azure Resource Graph Explorer (Draft Query)
resources
| where type == "microsoft.network/virtualnetworks"
| project subscriptionId, name, location, properties.addressSpace.addressPrefixes, properties.virtualNetworkPeerings
| where properties_virtualNetworkPeerings contains "properties"  // Virtual Network Peering connection exists
| join kind = leftouter (ResourceContainers
| where type =~ 'microsoft.resources/subscriptions'
| project subscriptionId, name)
on subscriptionId
// Azure Commercial
| where properties_addressSpace_addressPrefixes contains "10.68" or  properties_addressSpace_addressPrefixes contains "10.72" or properties_addressSpace_addressPrefixes contains "10.76"
// | where properties_addressSpace_addressPrefixes contains "10.68"
// where properties_addressSpace_addressPrefixes contains "10.72"
// | where properties_addressSpace_addressPrefixes contains "10.76"
// Azure Government
// | where properties_addressSpace_addressPrefixes contains "10.70" or  properties_addressSpace_addressPrefixes contains "10.74" or properties_addressSpace_addressPrefixes contains "10.78"
// | where properties_addressSpace_addressPrefixes contains "10.70"
// | where properties_addressSpace_addressPrefixes contains "10.74"
// | where properties_addressSpace_addressPrefixes contains "10.78"
| where name !contains "stand-alone" // Not Required - Does not contain any peering connections / Filter accomplished by  where properties_virtualNetworkPeerings contains "properties"
| order by ['name1'] asc


**Azure Commercial Data Center Basic Zone**
| VNET              | ***Location*** / Subscription   | Comments |
| :---------------- | :------------------------------ | :------- |
| 10.72.0.0/16      | ***Basic DNS Zone***                |          |
| 10.72.0.0/20      | ***CLOUDOPS Management\Platform *** |          |
| - 10.72.0.0/24    | MVP-CONNECTIVITY                |          |
| - 10.72.1.0/24    | F9INFRA-IDENTITY                  |          |
| **10.72.X.X/24**  |                                 |          |
| - 10.72.5.0/24    | AVD-PROD                        |          |
| - 10.72.7.0/24    | CORP-CONTAINERTEAM              |          |
| - 10.72.8.0/24    | CORP-CONTAINERTEAM              |          |
| - 10.72.9.0/24    | CORP-CONTAINERTEAM              |          |
| - 10.72.10.0/24   | SUB-CORP-VM-NP-001              |          |
| - 10.72.11.0/24   | SUB-CORP-DB-NP-001              |          |
| - 10.72.12.0/24   | SUB-CORP-CTR-NP-001             |          |
| - 10.72.13.0/25   | SUB-CORP-DB-PRD-001             |          |
