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
    $DisplayName = "RG-$ResourceGroup-$($Role)s".Replace(' ','-').ToLower()
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
    New-AzADGroup -DisplayName $DisplayName -Description $Description -MailNickName $DisplayName
}
catch {
    Write-Error "$($DisplayName) has not been created: $_"
}
