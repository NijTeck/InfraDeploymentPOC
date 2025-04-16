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
    HelpMessage="Enter Resource Group name")]
    [String]$ResourceGroup,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter RBAC Role")]
    [String]
    $Role
)

try {
    $ResourceGroup = $ResourceGroup.ToLower()
    $ResourceGroup
    $Role = $Role.ToLower()
    $Role
    $DisplayName = "$ResourceGroup-$($Role)s".Replace(' ','-').ToLower()
    $DisplayName
    If ($Role -eq "contributor" -or $Role -eq "owner" -or $Role -eq "reservation administrator"  -or $Role -eq "role based access control administrator" -or $Role -eq "user access administrator")
    {
        $Description = "Purpose: $ResourceGroup (resource group) rbac assignment / privileged identity management (No members)"
    }
    else
    {
        $Description = "Purpose: $ResourceGroup (resource group) rbac assignment"
    }
    $Description
    Update-AzADGroup -ObjectId $ObjectId -DisplayName $DisplayName -Description $Description -MailNickName $DisplayName -ErrorAction Stop
}
catch {
    Write-Error "$($DisplayName) has not been modified: $_"
}
