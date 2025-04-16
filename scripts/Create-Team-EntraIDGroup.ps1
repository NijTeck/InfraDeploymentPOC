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
    HelpMessage="Enter Department Name")]
    [String]$Department,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Team Name")]
    [String]
    $Team,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Sub-Team or Role")]
    [String]
    $Subteam
)

try {
    $Department = $Department.ToLower()
    $Department
    $Team = $Team.ToLower()
    $Team
    $Subteam = $Subteam.ToLower()
    $Subteam
    $DisplayName = "az-$Department-$($Team)-$($Subteam)".Replace(' ','-').ToLower()
    $DisplayName
    $Description = "Purpose: A department sub-team that's either directly grant PIM eligibility or indirectly grant a rbac assignment"
    $Description
    New-AzADGroup -DisplayName $DisplayName -Description $Description -MailNickName $DisplayName
}
catch {
    Write-Error "$($DisplayName) has not been created: $_"
}

