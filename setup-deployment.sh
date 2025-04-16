#!/bin/bash
# Script to set up the deployment environment with all necessary folders and files

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="./"
TEMPLATES_DIR="$BASE_DIR/templates"
CONFIG_DIR="$BASE_DIR/config"

# Subscription information
declare -A SUBSCRIPTIONS
SUBSCRIPTIONS=(
  ["commnp-sub"]="921fd8cb-0c80-44cf-9fd5-2a7c8f2f8674:25f11d80-28be-4f01-b1f6-6e5bfb927671:comm-np:10.81.128.0/17:Non-Production"
  ["commprod-sub"]="94010bcc-f819-44ae-8f50-9a69e46d6bb7:7ad47311-d1ac-47fe-8359-9a3d5dafef2e:comm-prod:10.81.0.0/17:Production"
  ["commonplat-prod-sub"]="::commonplat-prod:10.82.0.0/17:Production"
  ["commonplat-np-sub"]="::commonplat-np:10.82.128.0/17:Non-Production"
  ["opsprod-sub"]="::ops-prod:10.83.0.0/17:Production"
  ["opsnp-sub"]="::ops-np:10.83.128.0/17:Non-Production"
  ["analytics-prod-sub"]="::analytics-prod:10.84.0.0/18:Production"
  ["analytics-np-sub"]="::analytics-np:10.84.64.0/18:Non-Production"
)

# Create main template directories
mkdir -p "$TEMPLATES_DIR"

# Copy master subscription template
echo -e "${GREEN}Creating master subscription template...${NC}"
cat > "$TEMPLATES_DIR/master-subscription-template.yml" << 'EOF'
# Master subscription template content here
EOF

# Create pipeline files for each subscription
for SUB_NAME in "${!SUBSCRIPTIONS[@]}"; do
  IFS=':' read -r SUB_ID SERVICE_CONN_ID ZONE CIDR SERVICE_CLASS <<< "${SUBSCRIPTIONS[$SUB_NAME]}"
  
  echo -e "${GREEN}Setting up $SUB_NAME...${NC}"
  
  # Create subscription directories
  mkdir -p "$CONFIG_DIR/$SUB_NAME/subscription"
  mkdir -p "$CONFIG_DIR/$SUB_NAME/resourcegroup"
  mkdir -p "$CONFIG_DIR/$SUB_NAME/network"
  mkdir -p "$CONFIG_DIR/$SUB_NAME/monitor"
  mkdir -p "$CONFIG_DIR/$SUB_NAME/backup"
  mkdir -p "$CONFIG_DIR/$SUB_NAME/recovery"
  
  # Create pipeline file
  echo -e "${YELLOW}Creating pipeline for $SUB_NAME...${NC}"
  cat > "$CONFIG_DIR/$SUB_NAME/azure-pipelines.yml" << EOF
steps:
  - template: ../../templates/master-subscription-template.yml
    parameters:
      subscriptionName: "$SUB_NAME"
      subscriptionId: "$SUB_ID"
      serviceConnectionId: "$SERVICE_CONN_ID"
      deployComponents:
        subscription: true
        resourceGroups: true
        network: true
        monitor: false
        backup: false
        recovery: false
EOF

  # Create network parameters
  echo -e "${YELLOW}Creating network parameters for $SUB_NAME...${NC}"
  
  # Extract CIDR information and calculate subnet ranges
  if [[ "$CIDR" == "10.81.0.0/17" ]]; then
    FRONTEND_SUBNET="10.81.0.0/24"
    BACKEND_SUBNET="10.81.1.0/24"
    PE_SUBNET="10.81.2.0/24"
  elif [[ "$CIDR" == "10.81.128.0/17" ]]; then
    FRONTEND_SUBNET="10.81.140.0/24"
    BACKEND_SUBNET="10.81.141.0/24"
    PE_SUBNET="10.81.142.0/24"
  elif [[ "$CIDR" == "10.82.0.0/17" ]]; then
    FRONTEND_SUBNET="10.82.0.0/24"
    BACKEND_SUBNET="10.82.1.0/24"
    PE_SUBNET="10.82.126.0/24"
  elif [[ "$CIDR" == "10.82.128.0/17" ]]; then
    FRONTEND_SUBNET="10.82.128.0/24"
    BACKEND_SUBNET="10.82.129.0/24"
    PE_SUBNET="10.82.254.0/24"
  elif [[ "$CIDR" == "10.83.0.0/17" ]]; then
    FRONTEND_SUBNET="10.83.0.0/24"
    BACKEND_SUBNET="10.83.1.0/24"
    PE_SUBNET="10.83.126.0/24"
  elif [[ "$CIDR" == "10.83.128.0/17" ]]; then
    FRONTEND_SUBNET="10.83.128.0/24"
    BACKEND_SUBNET="10.83.129.0/24"
    PE_SUBNET="10.83.254.0/24"
  elif [[ "$CIDR" == "10.84.0.0/18" ]]; then
    FRONTEND_SUBNET="10.84.0.0/24"
    BACKEND_SUBNET="10.84.1.0/24"
    PE_SUBNET="10.84.62.0/24"
  elif [[ "$CIDR" == "10.84.64.0/18" ]]; then
    FRONTEND_SUBNET="10.84.64.0/24"
    BACKEND_SUBNET="10.84.65.0/24"
    PE_SUBNET="10.84.126.0/24"
  else
    echo -e "${RED}Invalid CIDR for $SUB_NAME: $CIDR${NC}"
    continue
  fi
  
  # Create network.basic.east.parameters.json
  cat > "$CONFIG_DIR/$SUB_NAME/network/network.basic.east.parameters.json" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "loc": {
      "value": "cus"
    },
    "network": {
      "value": {
        "deployVnet": true,
        "zone": "$ZONE",
        "addressPrefixes": [
          "$CIDR"
        ],
        "dnsServers": [
          "10.70.70.4",
          "10.70.70.5",
          "168.63.129.16",
          "10.70.1.4"
        ],
        "name": "spoke-vnet",
        "lock": {
          "kind": "CanNotDelete",
          "name": "Virtual Network Resource lock"
        },
        "peering": {
          "enabled": true,
          "spokesubid": "$SUB_ID",
          "transitrg": "network-vwan-hub-rg",
          "transitsubid": "daed0036-c29a-4894-806b-33313ce245db"
        },
        "deployNetworkWatcherRG": false,
        "resourceGroupTags": {
          "ServiceClass": "$SERVICE_CLASS",
          "Compliance": "PCI",
          "ManagedBy": "IaC"
        },
        "subnets": [
          {
            "comments": "frontend-snet for compute resources",
            "name": "frontend-snet",
            "addressPrefix": "$FRONTEND_SUBNET",
            "delegation": {
              "enabled": false
            },
            "nsg": {
              "enabled": true
            },
            "privateEndpointNetworkPolicies": "Enabled",
            "udr": {
              "enabled": true,
              "disableBgpRoutePropagation": false,
              "routes": [
                {
                  "name": "default",
                  "properties": {
                    "addressPrefix": "0.0.0.0/0",
                    "hasBgpOverride": false,
                    "nextHopType": "VirtualNetworkGateway"
                  }
                }
              ]
            }
          },
          {
            "comments": "backend-snet",
            "name": "backend-snet",
            "addressPrefix": "$BACKEND_SUBNET",
            "delegation": {
              "enabled": false
            },
            "nsg": {
              "enabled": true
            },
            "privateEndpointNetworkPolicies": "Enabled",
            "udr": {
              "enabled": true,
              "disableBgpRoutePropagation": false,
              "routes": [
                {
                  "name": "default",
                  "properties": {
                    "addressPrefix": "0.0.0.0/0",
                    "hasBgpOverride": false,
                    "nextHopType": "VirtualNetworkGateway"
                  }
                }
              ]
            }
          },
          {
            "comments": "pe-snet for private endpoints",
            "name": "pe-snet",
            "addressPrefix": "$PE_SUBNET",
            "delegation": {
              "enabled": false
            },
            "nsg": {
              "enabled": true
            },
            "privateEndpointNetworkPolicies": "Enabled",
            "udr": {
              "enabled": true,
              "disableBgpRoutePropagation": false,
              "routes": [
                {
                  "name": "default",
                  "properties": {
                    "addressPrefix": "0.0.0.0/0",
                    "hasBgpOverride": false,
                    "nextHopType": "VirtualNetworkGateway"
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}
EOF

  # Create subscription parameters
  echo -e "${YELLOW}Creating subscription parameters for $SUB_NAME...${NC}"
  cat > "$CONFIG_DIR/$SUB_NAME/subscription/east.parameters.json" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "subscriptionTags": {
      "value": {
        "Environment": "$SERVICE_CLASS",
        "Department": "IT"
      }
    },
    "subscriptionRoleAssignments": {
      "value": [
        {
          "comments": "Built-in Role: Contributor (rbac-$SUB_NAME-contributor)",
          "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c",
          "securityGroupObjectIds": [
            "b124406e-9e3e-49e8-a008-72a317960fc9"
          ]
        }
      ]
    }
  }
}
EOF

  # Create resourcegroup parameters (basic template)
  echo -e "${YELLOW}Creating resourcegroup parameters for $SUB_NAME...${NC}"
  cat > "$CONFIG_DIR/$SUB_NAME/resourcegroup/resourcegroup.east.parameters.json" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "loc": {
      "value": "cus"
    },
    "workloads": {
      "value": {
        "resourceGroups": [
          {
            "name": "${SUB_NAME%-sub}-app",
            "tags": {
              "Criticality": "$SERVICE_CLASS",
              "ServiceClass": "$SERVICE_CLASS",
              "WorkloadName": "Application Workload"
            }
          },
          {
            "name": "${SUB_NAME%-sub}-data",
            "tags": {
              "Criticality": "$SERVICE_CLASS",
              "ServiceClass": "$SERVICE_CLASS",
              "WorkloadName": "Data Storage"
            }
          }
        ],
        "deployNetworkWatcherRG": false,
        "tags": {
          "Environment": "$SERVICE_CLASS",
          "Department": "IT"
        }
      }
    },
    "roleDefinitionId": {
      "value": "/subscriptions/$SUB_ID/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
    },
    "principalId": {
      "value": "b124406e-9e3e-49e8-a008-72a317960fc9"
    }
  }
}
EOF

  echo -e "${YELLOW}Creating monitor parameters for $SUB_NAME...${NC}"
  cat > "$CONFIG_DIR/$SUB_NAME/monitor/east.parameters.json" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "loc": {
      "value": "cus"
    },
    "subscription": {
      "value": {
        "name": "${SUB_NAME%-sub}"
      }
    },
    "monitor": {
      "value": {
        "actionGroup": {
          "actionGroupName": "action-group",
          "actionGroupShortName": "actgrp",
          "webhookReceivers": []
        },
        "resourceGroupTags": {
          "Criticality": "$SERVICE_CLASS",
          "ProductId": "PL24_1698",
          "WorkloadName": "Infrastructure Monitoring"
        },
        "serviceHealth": {
          "alertRuleName": "Service Health - Platform Notifications",
          "alertRuleDescription": "Alert on service health incidents",
          "condition": [
            {
              "field": "category",
              "equals": "ServiceHealth",
              "containsAny": null
            },
            {
              "field": "properties.impactedServices[*].ImpactedRegions[*].RegionName",
              "containsAny": [
                "Global",
                "central us"
              ]
            }
          ],
          "webhookProperties": {
            "owner": "${SUB_NAME%-sub}",
            "serviceClass": "$SERVICE_CLASS"
          }
        },
        "activityLogAlerts": [
          {
            "name": "Azure Security Solutions Write",
            "isEnabled": true,
            "alertDescription": "Alert when security solutions are written",
            "actions": [],
            "conditions": [
              {
                "field": "category",
                "equals": "Administrative"
              },
              {
                "field": "operationName",
                "equals": "Microsoft.Security/securitySolutions/write"
              }
            ]
          },
          {
            "name": "SQL Server Firewall Rule Delete",
            "isEnabled": true,
            "alertDescription": "Alert when SQL Server firewall rules are deleted",
            "actions": [],
            "conditions": [
              {
                "field": "category",
                "equals": "Administrative"
              },
              {
                "field": "operationName",
                "equals": "Microsoft.Sql/servers/firewallRules/delete"
              }
            ]
          }
        ]
      }
    }
  }
}
EOF

done

echo -e "${GREEN}Setup complete! Generated configuration for all subscriptions.${NC}"
echo -e "${YELLOW}Note: Some subscription IDs and service connection IDs are empty and need to be filled in.${NC}"