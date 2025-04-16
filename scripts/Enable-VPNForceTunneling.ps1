<#
.Synopsis

.DESCRIPTION

.EXAMPLE

.EXAMPLE

.NOTES
   Version:  0.1.0
#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Local Network Gateway Name")]
    [String]$LocalNetworkGateway,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Resource Group Name")]
    [String]$ResourceGroupName,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter Virtual Gateway Name")]
    [String]$VirtualNetworkGateway
)

$LocalGateway   = Get-AzLocalNetworkGateway   -Name $LocalNetworkGateway   -ResourceGroupName $ResourceGroupName
$VirtualGateway = Get-AzVirtualNetworkGateway -Name $VirtualNetworkGateway -ResourceGroupName $ResourceGroupName

Set-AzVirtualNetworkGatewayDefaultSite -GatewayDefaultSite $LocalGateway -VirtualNetworkGateway $VirtualGateway

# How to remove force tunneling ...
# $Gateway = Get-AzVirtualNetworkGateway -Name $VirtualNetworkGateway
# Remove-AzVirtualNetworkGatewayDefaultSite -VirtualNetworkGateway $Gateway