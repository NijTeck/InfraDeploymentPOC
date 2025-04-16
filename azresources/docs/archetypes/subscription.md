# Subscription Configuration

# Configuration Parameter File

## JSON Schema and Version (Required)
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
## Short Location Name
        "loc":{
            "value": "east"                                                                     // Required, but not used
        },
## Subscription Management Group
        "subscriptionMG": {
            "value": {
                "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",                                   // Required
                "targetMgId": "xxxxxxxxxx"                                                      // Required
            }
        },
        "subscriptionRoleAssignments": {
## No Subscription Role Assignments
            "value": [                                                                          // Optional: No Role Assignments
            ]
## Single Subscription Role Assignments
            "value": [                                                                          // Optional: One Role Assignments
                {
                    "comments": "Built-in Role: Role Name (Entra ID Security Group Name)",      // Used as a reference
                    "roleDefinitionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",                 // Role ID
                    "securityGroupObjectIds": [
                        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"                                  // **Single** Security Group ID
                    ]
                }
            ]
## Multiple Subscription Role Assignments (with one or more security groups per role assignment)
            "value": [                                                                          // Optional: Multiple Role Assignments
                {
                    "comments": "Built-in Role: Role Name (Entra ID Security Group Name)",      // Used as a reference
                    "roleDefinitionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",                 // Role ID
                    "securityGroupObjectIds": [
                        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"                                  // **Single** Security Group ID
                    ]
                },
                {
                    "comments": "Built-in Role: Role Name (Entra ID Security Group Name)",      // Used as a reference
                    "roleDefinitionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",                 // Role ID
                    "securityGroupObjectIds": [
                        "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",                                 // Supports **Multiple** Security Group IDs
                        "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"                                  // **Note:** Multiple Security Group IDs is a "Non-Standard" configuration
                    ]
                }
            ]
        },
## Subscription Tags
        "subscriptionTags": {
            "value": {                                                                          // Optional: Array of Key / Value Pairs
                "ServiceClass": "Non-Production"                                                // Required: ServiceClass
            }
        }
    }


# Additional Information

## Short Location Name
- Azure Commercial: east (Default Value)
- Azure Government: usva (Default Value)

## Role Assignment
| Role                                    | Recommendation | PIM |
|-----------------------------------------|----------------|-----|
| Contributor                             | **Suggested**     | Yes |
| Network Contributor                     | Optional       | No  |
| Owner                                   | Discouraged    | Yes |
| Reader                                  | **Suggested**     | No  |
| Reservation Administrator               | Optional       | Yes |
| Role Based Access Control Administrator | Optional       | Yes |
| Support Request Contributor             | Optional       | No  |
| User Access Administrator               | Discouraged    | Yes |

**Note:** Additional information regarding Azure Roles and Role Definition Ids can be found here:

https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

## Tags
By Azure Policy, the "ServiceClass" **key** is required.
- Acceptable values: "Non-Production" or "Production"

# Maintainer
* Leonard Esere - [leonard.esere@flyfrontier.com](mailto:leonard.esere@flyfrontier.com)
