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
    HelpMessage="Enter Management Group name")]
    [String]$ManagementGroup,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter RBAC Role")]
    [String]
    $Role
)

try {
    $ManagementGroup = $ManagementGroup.ToLower()
    $ManagementGroup
    $Role = $Role.ToLower()
    $Role
    $DisplayName = "MG-$ManagementGroup-$($Role)s".Replace(' ','-').ToLower()
    $DisplayName
    If ($Role -eq "contributor" -or $Role -eq "owner" -or $Role -eq "reservation administrator"  -or $Role -eq "role based access control administrator" -or $Role -eq "user access administrator")
    {
        $Description = "Purpose: $ManagementGroup (management group) rbac assignment / privileged identity management (No members)"
    }
    else
    {
        $Description = "Purpose: $ManagementGroup (management group) rbac assignment"
    }
    $Description
    New-AzADGroup -DisplayName $DisplayName -Description $Description -MailNickName $DisplayName -ErrorAction Stop
}
catch {
    Write-Error "$($DisplayName) has not been created: $_"
}
