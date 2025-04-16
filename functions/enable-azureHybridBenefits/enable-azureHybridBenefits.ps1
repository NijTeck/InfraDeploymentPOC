$Subscriptions = Get-AzManagementGroupSubscription -GroupName "f9infra-core-it"

Write-Output 'Gather subscriptions:' $Subscriptions

$SkipSubscriptions = @(
#    "b4d714fa-a345-4251-a76c-3b91e9ec84b1",
#    "c85af8a5-c6bd-4189-89fd-244034444580"
)

foreach ($Subscription in $Subscriptions) {
    if ($SkipSubscriptions -contains $Subscription.id){
        Write-Output "Skipping subscription: [$($Subscription.DisplayName)]"
    }
    Set-AzContext -Subscription $subscription.DisplayName
    Write-Output "Gather $($subscription.DisplayName) VMs:"
    $VMs = Get-AzVM -Status | Where {$_.StorageProfile.OsDisk.OsType -eq "Windows" -and (!($_.LicenseType))} | Select-Object Name, ResourceGroupName, LicenseType
    ForEach ($VM in $VMs) {
        Write-Output "Enabling Azure Hybrid Benefit on $($VM.Name)"
    }
}