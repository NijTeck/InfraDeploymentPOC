<#
.Synopsis

.DESCRIPTION

.EXAMPLE

.NOTES
   Version:  0.2.0
#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Group Object Id")]
    [String]$ObjectId,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Subscription name")]
    [String]$Subscription,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter RBAC Role")]
    [String]
    $Role
)

try {
    $Subscription = $Subscription.ToLower()
    $Subscription
    $Role = $Role.ToLower()
    $Role
    $DisplayName = "$Subscription-$($Role)s".Replace(' ','-').ToLower()
    $DisplayName
    If ($Role -eq "contributor" -or $Role -eq "owner" -or $Role -eq "reservation administrator"  -or $Role -eq "role based access control administrator" -or $Role -eq "user access administrator")
    {
        $Description = "Purpose: $Subscription (subscription) rbac assignment / privileged identity management (No members)"
    }
    else
    {
        $Description = "Purpose: $Subscription (subscription) rbac assignment"
    }
    $Description
    Update-AzADGroup -ObjectId $ObjectId -DisplayName $DisplayName -Description $Description -MailNickName $DisplayName -ErrorAction Stop
}
catch {
    Write-Error "$($DisplayName) has not been modified: $_"
}