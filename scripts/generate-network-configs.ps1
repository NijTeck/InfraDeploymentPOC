# Script to generate network configurations for each subscription
param(
    [string]$OutputPath = "./config"
)

# Define subscription data
$subscriptions = @(
    @{
        Name = "commprod-sub"
        Zone = "comm-prod"
        CIDR = "10.81.0.0/17"
        ServiceConnectionId = "25f11d80-28be-4f01-b1f6-6e5bfb927671"
        SubscriptionId = "94010bcc-f819-44ae-8f50-9a69e46d6bb7"
        ServiceClass = "Production"
        Subnets = @{
            Frontend = "10.81.0.0/24"
            Backend = "10.81.1.0/24"
            PrivateEndpoint = "10.81.2.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "commnp-sub"
        Zone = "comm-np"
        CIDR = "10.81.128.0/17"
        ServiceConnectionId = "25f11d80-28be-4f01-b1f6-6e5bfb927671"
        SubscriptionId = "921fd8cb-0c80-44cf-9fd5-2a7c8f2f8674"
        ServiceClass = "Non-Production"
        Subnets = @{
            Frontend = "10.81.140.0/24"
            Backend = "10.81.141.0/24"
            PrivateEndpoint = "10.81.142.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "commonplat-prod-sub"
        Zone = "commonplat-prod"
        CIDR = "10.82.0.0/17"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Production"
        Subnets = @{
            Frontend = "10.82.0.0/24"
            Backend = "10.82.1.0/24"
            PrivateEndpoint = "10.82.126.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "commonplat-np-sub"
        Zone = "commonplat-np"
        CIDR = "10.82.128.0/17"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Non-Production"
        Subnets = @{
            Frontend = "10.82.128.0/24"
            Backend = "10.82.129.0/24"
            PrivateEndpoint = "10.82.254.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "opsprod-sub"
        Zone = "ops-prod"
        CIDR = "10.83.0.0/17"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Production"
        Subnets = @{
            Frontend = "10.83.0.0/24"
            Backend = "10.83.1.0/24"
            PrivateEndpoint = "10.83.126.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "opsnp-sub"
        Zone = "ops-np"
        CIDR = "10.83.128.0/17"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Non-Production"
        Subnets = @{
            Frontend = "10.83.128.0/24"
            Backend = "10.83.129.0/24"
            PrivateEndpoint = "10.83.254.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "analytics-prod-sub"
        Zone = "analytics-prod"
        CIDR = "10.84.0.0/18"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Production"
        Subnets = @{
            Frontend = "10.84.0.0/24"
            Backend = "10.84.1.0/24"
            PrivateEndpoint = "10.84.62.0/24"  # Last /24 subnet in range
        }
    },
    @{
        Name = "analytics-np-sub"
        Zone = "analytics-np"
        CIDR = "10.84.64.0/18"
        ServiceConnectionId = ""  # Fill in actual ID
        SubscriptionId = ""       # Fill in actual ID
        ServiceClass = "Non-Production"
        Subnets = @{
            Frontend = "10.84.64.0/24"
            Backend = "10.84.65.0/24"
            PrivateEndpoint = "10.84.126.0/24"  # Last /24 subnet in range
        }
    }
)

# Template for network parameters
$networkParametersTemplate = Get-Content -Raw -Path "network-parameters-template.json"

# Generate configurations for each subscription
foreach ($sub in $subscriptions) {
    # Create directory if it doesn't exist
    $subDir = Join-Path -Path $OutputPath -ChildPath $sub.Name
    $networkDir = Join-Path -Path $subDir -ChildPath "network"
    
    if (-not (Test-Path $networkDir)) {
        New-Item -Path $networkDir -ItemType Directory -Force | Out-Null
    }

    # Replace tokens in template
    $networkParams = $networkParametersTemplate `
        -replace '\[SUBSCRIPTION_ZONE\]', $sub.Zone `
        -replace '\[CIDR_BLOCK\]', $sub.CIDR `
        -replace '\[SUBSCRIPTION_ID\]', $sub.SubscriptionId `
        -replace '\[SERVICE_CLASS\]', $sub.ServiceClass `
        -replace '\[FRONTEND_SUBNET\]', $sub.Subnets.Frontend `
        -replace '\[BACKEND_SUBNET\]', $sub.Subnets.Backend `
        -replace '\[PE_SUBNET\]', $sub.Subnets.PrivateEndpoint

    # Write network parameters file
    $outputFile = Join-Path -Path $networkDir -ChildPath "network.basic.east.parameters.json"
    $networkParams | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "Generated network configuration for $($sub.Name)"
}

Write-Host "Configuration generation complete!"