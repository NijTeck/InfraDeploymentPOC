# Script to generate individual subscription pipeline files
param(
    [string]$OutputPath = "./config"
)

# Define subscription data
$subscriptions = @(
    @{
        Name = "commnp-sub"
        SubscriptionId = "921fd8cb-0c80-44cf-9fd5-2a7c8f2f8674"
        ServiceConnectionId = "25f11d80-28be-4f01-b1f6-6e5bfb927671"
    },
    @{
        Name = "commprod-sub"
        SubscriptionId = "94010bcc-f819-44ae-8f50-9a69e46d6bb7"
        ServiceConnectionId = "7ad47311-d1ac-47fe-8359-9a3d5dafef2e"
    },
    @{
        Name = "commonplat-prod-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    },
    @{
        Name = "commonplat-np-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    },
    @{
        Name = "opsprod-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    },
    @{
        Name = "opsnp-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    },
    @{
        Name = "analytics-prod-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    },
    @{
        Name = "analytics-np-sub"
        SubscriptionId = ""  # Fill in actual ID
        ServiceConnectionId = ""  # Fill in actual ID
    }
)

# Template for pipeline YAML
$pipelineTemplate = @'
steps:
  - template: ../../templates/subscription-pipeline-template.yml
    parameters:
      subscriptionName: "{0}"
      subscriptionId: "{1}"
      serviceConnectionId: "{2}"
'@

# Generate pipeline files for each subscription
foreach ($sub in $subscriptions) {
    # Create directory if it doesn't exist
    $subDir = Join-Path -Path $OutputPath -ChildPath $sub.Name
    
    if (-not (Test-Path $subDir)) {
        New-Item -Path $subDir -ItemType Directory -Force | Out-Null
    }

    # Format the pipeline content with subscription-specific values
    $pipelineContent = $pipelineTemplate -f $sub.Name, $sub.SubscriptionId, $sub.ServiceConnectionId

    # Write pipeline file
    $outputFile = Join-Path -Path $subDir -ChildPath "azure-pipelines.yml"
    $pipelineContent | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "Generated pipeline for $($sub.Name)"
}

Write-Host "Pipeline generation complete!"