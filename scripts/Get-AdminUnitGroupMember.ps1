# Variables
$adminUnit = "Azure Group Management"
$groupResults=@()
$groupMemberResults =@()
$groupOwnerResults=@()
$groupMemberOfResults=@()
$eligibilityResults=@()

Connect-MgGraph -Scopes "AdministrativeUnit.Read.All", "Group.Read.All", "User.Read.All"

# Get Administrative Unit
$adminUnitObj = Get-MgDirectoryAdministrativeUnit -Filter "DisplayName eq '$adminUnit'"

# Get All Administrative Unit Object
ForEach ($object in (Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $adminUnitObj.Id -All))
{
    # Processes each group
    if($object.AdditionalProperties."@odata.type" -eq "#microsoft.graph.group")
    {
        # Retrieve group information
        $Group = Get-MgGroup -GroupId $object.Id
        $GroupObject = New-Object -TypeName PSObject -Property @{
            "GroupID" = $Group.ID
            "GroupDisplayName" = $Group.DisplayName
            "GroupDescription" = $Group.Description
        }
        $groupResults += $GroupObject

        $Members = Get-MgGroupMember -GroupId $Group.ID
        if ($Members.Count -gt 0 -And $Group.DisplayName -like '*owners')
        {
            Write-Host $Group.DisplayName "should not contain members" -ForegroundColor DarkRed
            $Status = 'Misconfigured'
        }
        elseif ($Members.Count -gt 0 -And $Group.DisplayName -like '*contributors' `
                -And $Group.DisplayName -notlike '*lab-services-contributors' `
                -And $Group.DisplayName -notlike '*monitoring-contributors' `
                -And $Group.DisplayName -notlike '*network-contributors' `
                -And $Group.DisplayName -notlike '*resource-policy-contributors')
        {
            Write-Host $Group.DisplayName "should not contain members" -ForegroundColor DarkRed
            $Status = 'Misconfigured'
        }
        else
        {
            $Status = 'Healthy'
        }

        If ($Members.Count -eq 0)
        {
            Write-Host $Group.DisplayName "has no members." -ForegroundColor DarkGreen
            ForEach ($C in $group)
            {
                # Create and populate member object with group data
                $MemberObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "GroupDescription" = $Group.Description
                    "MemberDisplayName" = "Empty Group"
                    "UserPrincipalName" = "N/A"
                    "UserId" = "N/A"
                    "Status" = $Status
                    "MemberType" = "N/A"
                    "Created" = $Group.CreatedDateTime
                }
            $groupMemberResults += $MemberObject
            }
        }
        else
        {
            Write-Host $Group.DisplayName "contains" $Members.Count "member(s)"
        }

        $groupOwner = Get-MgGroupOwnerAsUser -GroupId $object.Id
        If ($groupOwner.Count -gt 0)
        {
            Write-Host "- " $Group.DisplayName "contains" $groupOwner.Count "owners(s)"
            ForEach ($A in $groupOwner)
            {
                $groupOwnerObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "OwnerDisplayName" = $A.DisplayName
                    "OwnerJobTitle" = $A.JobTitle
                    "OwnerUserPrincipalName" = $A.UserPrincipalName
                }
            $groupOwnerResults += $groupOwnerObject
            }
        }

        $groupMemberAsGroup = Get-MgGroupMemberAsGroup -GroupId $object.Id
        If ($groupMemberAsGroup.Count -gt 0)
        {
            Write-Host "- " $Group.DisplayName "contains" $groupMemberAsGroup.Count "group(s)"
            ForEach ($B in $groupMemberAsGroup)
            {
                # Create and populate member object with group data
                $MemberObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "GroupDescription" = $Group.Description
                    "MemberDisplayName" = $B.DisplayName
                    "UserPrincipalName" = "N/A"
                    "MemberId" = $B.Id
                    "Status" = $Status
                    "MemberType" = "Group"
                    "Created" = $B.CreatedDateTime
                }
            $groupMemberResults += $MemberObject
            }
        }

        $groupMemberAsUser = Get-MgGroupMemberAsUser -GroupId $object.Id
        If ($groupMemberAsUser.Count -gt 0)
        {
            Write-Host "- " $Group.DisplayName "contains" $groupMemberAsUser.Count "user(s)"
            ForEach ($C in $groupMemberAsUser)
            {
                # Create and populate member object with user data
                Write-Host "  - " $C.DisplayName
                $MemberObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "GroupDescription" = $Group.Description
                    "MemberDisplayName" = $C.DisplayName
                    "UserPrincipalName" = $C.UserPrincipalName
                    "UserId" = $C.Id
                    "Status" = $Status
                    "MemberType" = "User"
                    "Created" = $Group.CreatedDateTime
                }
            $groupMemberResults += $MemberObject
            }
        }

        $groupMemberOf = Get-MgGroupMemberOfAsGroup -GroupId $object.Id
        If ($groupMemberOf.Count -gt 0)
        {
            Write-Host "- " $Group.DisplayName "is a member of" $groupMemberOf.Count "group(s)"
            ForEach ($D in $groupMemberOf)
            {
                $groupMemberOfObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "MemberOfDisplayName" = $D.DisplayName
                }
            $groupMemberOfResults += $groupMemberOfObject
            }
        }

        $eligibility = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance -Filter ("groupId eq '{0}'" -f $($object.Id))
        If ($eligibility.Count -gt 0)
        {
            Write-Host "- " $Group.DisplayName "contains" $eligibility.Count "eligible group(s)"
            ForEach ($E in $eligibility)
            {
                $eligibilityMemberObject = New-Object -TypeName PSObject -Property @{
                    "GroupID" = $Group.ID
                    "GroupDisplayName" = $Group.DisplayName
                    "PrincipalId" = $E.PrincipalId
                    "MemberType" = $E.MemberType
                    "StartDateTime" = $E.StartDateTime
                    "EndDateTime" = $E.EndDateTime
                }
            $eligibilityResults += $eligibilityMemberObject
            }
        }
    }
}
Write-Host "Groups"
$groupResults | Select GroupId, GroupDisplayName, GroupDescription | Export-Csv .\output\groupResults.csv
Write-Host "Group Members"
$groupMemberResults | Select GroupID, GroupDisplayName, GroupDescription, MemberDisplayName, UserPrincipalName, UserId, Status, MemberType, Created | Export-Csv .\output\groupMemberResults.Csv
Write-Host "Group Owners"
$groupOwnerResults | Select GroupId, GroupDisplayName, OwnerDisplayName, OwnerJobTitle, OwnerUserPrincipalName | Export-Csv .\output\groupOwnerResults.csv
Write-Host "Group Member Of"
$groupMemberOfResults | Select GroupId, GroupDisplayName, MemberOfDisplayName | Export-Csv .\output\groupMemberOfResults.csv
Write-Host "Group Eligibility"
$eligibilityResults | Select GroupId, GroupDisplayName, MemberType, PrincipalId, StartDateTime, EndDateTime | Export-Csv .\output\eligibilityResults.csv


